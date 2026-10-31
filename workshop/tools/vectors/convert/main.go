// convert: writes minilm.bin, the model file of vectors, from the Hugging Face files of
// sentence-transformers/all-MiniLM-L6-v2 (Apache 2.0): model.safetensors and vocab.txt.
//
//	go run ./convert <folder with model.safetensors and vocab.txt> <minilm.bin>
//
// The weight matrices become one byte per number with a scale per row (see model.go);
// the small vectors (biases, layer norms, positions) stay float32.
package main

import (
	"bufio"
	"bytes"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

const maxTokens = 256 // the length the model was trained for: longer texts are cut

type tensor struct {
	Name   string `json:"name"`
	Kind   string `json:"kind"`
	Shape  []int  `json:"shape"`
	Offset int    `json:"offset"`
}

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintln(os.Stderr, "usage: go run ./convert <hugging face folder> <minilm.bin>")
		os.Exit(2)
	}
	dir, out := os.Args[1], os.Args[2]
	raw, err := os.ReadFile(filepath.Join(dir, "model.safetensors"))
	check(err)
	n := binary.LittleEndian.Uint64(raw[:8])
	var meta map[string]json.RawMessage
	check(json.Unmarshal(raw[8:8+n], &meta))
	data := raw[8+n:]
	var names []string
	for k := range meta {
		if k != "__metadata__" && k != "embeddings.position_ids" && !strings.HasPrefix(k, "pooler.") {
			names = append(names, k)
		}
	}
	sort.Strings(names)
	var body bytes.Buffer
	var tensors []tensor
	for _, name := range names {
		var t struct {
			Dtype   string `json:"dtype"`
			Shape   []int  `json:"shape"`
			Offsets [2]int `json:"data_offsets"`
		}
		check(json.Unmarshal(meta[name], &t))
		if t.Dtype != "F32" {
			check(fmt.Errorf("%s is %s, not F32", name, t.Dtype))
		}
		vals := make([]float32, (t.Offsets[1]-t.Offsets[0])/4)
		for i := range vals {
			vals[i] = math.Float32frombits(binary.LittleEndian.Uint32(data[t.Offsets[0]+4*i:]))
		}
		shape := t.Shape
		if name == "embeddings.position_embeddings.weight" {
			shape = []int{maxTokens, shape[1]}
			vals = vals[:maxTokens*shape[1]]
		}
		tn := tensor{Name: name, Shape: shape, Offset: body.Len(), Kind: "f32"}
		if len(shape) == 2 && strings.HasSuffix(name, ".weight") && shape[0] > 2 && name != "embeddings.position_embeddings.weight" {
			tn.Kind = "i8"
			rows, cols := shape[0], shape[1]
			q := make([]byte, rows*cols)
			for r := 0; r < rows; r++ {
				var top float64
				for _, v := range vals[r*cols : (r+1)*cols] {
					top = math.Max(top, math.Abs(float64(v)))
				}
				scale := float32(top / 127)
				check(binary.Write(&body, binary.LittleEndian, scale))
				for c, v := range vals[r*cols : (r+1)*cols] {
					if scale > 0 {
						q[r*cols+c] = byte(int8(math.Round(float64(v / scale))))
					}
				}
			}
			body.Write(q)
		} else {
			check(binary.Write(&body, binary.LittleEndian, vals))
		}
		tensors = append(tensors, tn)
	}
	vocab, err := readLines(filepath.Join(dir, "vocab.txt"))
	check(err)
	head, err := json.Marshal(map[string]any{
		"source":     "https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2",
		"license":    "Apache-2.0",
		"hidden":     384,
		"layers":     6,
		"heads":      12,
		"max_tokens": maxTokens,
		"vocab":      vocab,
		"tensors":    tensors,
	})
	check(err)
	f, err := os.Create(out)
	check(err)
	w := bufio.NewWriter(f)
	w.WriteString("VECTORS1")
	check(binary.Write(w, binary.LittleEndian, uint32(len(head))))
	w.Write(head)
	w.Write(body.Bytes())
	check(w.Flush())
	check(f.Close())
}

func readLines(path string) ([]string, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	return strings.Split(strings.TrimRight(string(b), "\n"), "\n"), nil
}

func check(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, "convert:", err)
		os.Exit(1)
	}
}
