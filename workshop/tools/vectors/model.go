package main

// MiniLM (all-MiniLM-L6-v2): a small BERT, six layers of 384 numbers, that turns a text into
// one vector of 384 numbers. Texts that mean the same thing get vectors that point the same
// way. This file reads the model and runs it on the processor, in plain Go.
//
// The model file, minilm.bin, is written by convert/ from the Hugging Face weights:
//   "VECTORS1", the length of a JSON header (4 bytes, little endian), the header, the data.
// The header holds the vocabulary and, for each tensor, its shape, kind and offset in the
// data. Kind "f32" is float32 numbers. Kind "i8" is one float32 scale per row, then one
// byte per number: the number is the byte times its row's scale. That keeps the file at a
// quarter of the original size, and the vectors almost the same (the test says how close).

import (
	"encoding/binary"
	"encoding/json"
	"fmt"
	"math"
	"os"
)

type header struct {
	Source    string   `json:"source"`
	License   string   `json:"license"`
	Hidden    int      `json:"hidden"`
	Layers    int      `json:"layers"`
	Heads     int      `json:"heads"`
	MaxTokens int      `json:"max_tokens"`
	Vocab     []string `json:"vocab"`
	Tensors   []tensor `json:"tensors"`
}

type tensor struct {
	Name   string `json:"name"`
	Kind   string `json:"kind"`
	Shape  []int  `json:"shape"`
	Offset int    `json:"offset"`
}

// rows8: a matrix kept as bytes, one scale per row: the word embeddings, read a row at a time.
type rows8 struct {
	cols  int
	scale []float32
	q     []int8
}

func (m *rows8) row(i int, out []float32) {
	s := m.scale[i]
	for j, v := range m.q[i*m.cols : (i+1)*m.cols] {
		out[j] = float32(v) * s
	}
}

// linear: y = x·Wᵀ + b, W with one row per output.
type linear struct {
	in, out int
	w, b    []float32
}

func (l *linear) apply(x []float32, n int) []float32 {
	y := make([]float32, n*l.out)
	for j := 0; j < l.out; j++ {
		w, b := l.w[j*l.in:(j+1)*l.in], l.b[j]
		for t := 0; t < n; t++ {
			y[t*l.out+j] = dot(x[t*l.in:(t+1)*l.in], w) + b
		}
	}
	return y
}

type layer struct {
	q, k, v, o, up, down linear
	ln1g, ln1b           []float32
	ln2g, ln2b           []float32
}

type model struct {
	tok                  *tokenizer
	hidden, heads, max   int
	word                 rows8
	pos, typ, embG, embB []float32
	layers               []layer
}

func load(path string) (*model, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	if len(data) < 12 || string(data[:8]) != "VECTORS1" {
		return nil, fmt.Errorf("%s is not a model file for this program", path)
	}
	n := int(binary.LittleEndian.Uint32(data[8:12]))
	var h header
	if err := json.Unmarshal(data[12:12+n], &h); err != nil {
		return nil, fmt.Errorf("%s: %v", path, err)
	}
	body := data[12+n:]
	byName := map[string]tensor{}
	for _, t := range h.Tensors {
		byName[t.Name] = t
	}
	var missing error
	get := func(name string) tensor {
		t, ok := byName[name]
		if !ok && missing == nil {
			missing = fmt.Errorf("%s: no tensor %s", path, name)
		}
		return t
	}
	f32 := func(name string) []float32 {
		t := get(name)
		size := 1
		for _, d := range t.Shape {
			size *= d
		}
		out := make([]float32, size)
		if t.Kind == "f32" {
			for i := range out {
				out[i] = math.Float32frombits(binary.LittleEndian.Uint32(body[t.Offset+4*i:]))
			}
			return out
		}
		r := i8(t, body)
		for i := 0; i < t.Shape[0]; i++ {
			r.row(i, out[i*r.cols:(i+1)*r.cols])
		}
		return out
	}
	lin := func(name string) linear {
		t := get(name + ".weight")
		if len(t.Shape) != 2 {
			return linear{}
		}
		return linear{in: t.Shape[1], out: t.Shape[0], w: f32(name + ".weight"), b: f32(name + ".bias")}
	}
	m := &model{tok: newTokenizer(h.Vocab), hidden: h.Hidden, heads: h.Heads, max: h.MaxTokens}
	m.word = i8(get("embeddings.word_embeddings.weight"), body)
	m.pos = f32("embeddings.position_embeddings.weight")
	m.typ = f32("embeddings.token_type_embeddings.weight")
	m.embG, m.embB = f32("embeddings.LayerNorm.weight"), f32("embeddings.LayerNorm.bias")
	for i := 0; i < h.Layers; i++ {
		p := fmt.Sprintf("encoder.layer.%d.", i)
		m.layers = append(m.layers, layer{
			q: lin(p + "attention.self.query"), k: lin(p + "attention.self.key"),
			v: lin(p + "attention.self.value"), o: lin(p + "attention.output.dense"),
			up: lin(p + "intermediate.dense"), down: lin(p + "output.dense"),
			ln1g: f32(p + "attention.output.LayerNorm.weight"), ln1b: f32(p + "attention.output.LayerNorm.bias"),
			ln2g: f32(p + "output.LayerNorm.weight"), ln2b: f32(p + "output.LayerNorm.bias"),
		})
	}
	return m, missing
}

func i8(t tensor, body []byte) rows8 {
	if len(t.Shape) != 2 {
		return rows8{}
	}
	rows, cols := t.Shape[0], t.Shape[1]
	r := rows8{cols: cols, scale: make([]float32, rows), q: make([]int8, rows*cols)}
	for i := range r.scale {
		r.scale[i] = math.Float32frombits(binary.LittleEndian.Uint32(body[t.Offset+4*i:]))
	}
	start := t.Offset + 4*rows
	for i := range r.q {
		r.q[i] = int8(body[start+i])
	}
	return r
}

// embed: the text's vector, 384 numbers of length 1 (the mean of its tokens, normalised).
func (m *model) embed(text string) []float32 {
	ids := m.tok.encode(text, m.max)
	n, d := len(ids), m.hidden
	x := make([]float32, n*d)
	row := make([]float32, d)
	for t, id := range ids {
		m.word.row(int(id), row)
		xt := x[t*d : (t+1)*d]
		for j := range xt {
			xt[j] = row[j] + m.pos[t*d+j] + m.typ[j]
		}
		layerNorm(xt, m.embG, m.embB)
	}
	for _, l := range m.layers {
		x = m.block(&l, x, n)
	}
	out := make([]float32, d)
	for t := 0; t < n; t++ {
		for j := range out {
			out[j] += x[t*d+j]
		}
	}
	normalise(out)
	return out
}

// block: one transformer layer, self-attention then the feed-forward, each with its residual.
func (m *model) block(l *layer, x []float32, n int) []float32 {
	d, hd := m.hidden, m.hidden/m.heads
	q, k, v := l.q.apply(x, n), l.k.apply(x, n), l.v.apply(x, n)
	ctx := make([]float32, n*d)
	p := make([]float32, n)
	scale := float32(1 / math.Sqrt(float64(hd)))
	for h := 0; h < m.heads; h++ {
		off := h * hd
		for i := 0; i < n; i++ {
			qi := q[i*d+off : i*d+off+hd]
			top := float32(math.Inf(-1))
			for j := 0; j < n; j++ {
				p[j] = dot(qi, k[j*d+off:j*d+off+hd]) * scale
				if p[j] > top {
					top = p[j]
				}
			}
			var sum float32
			for j := 0; j < n; j++ {
				p[j] = float32(math.Exp(float64(p[j] - top)))
				sum += p[j]
			}
			ci := ctx[i*d+off : i*d+off+hd]
			for j := 0; j < n; j++ {
				w := p[j] / sum
				vj := v[j*d+off : j*d+off+hd]
				for c := range ci {
					ci[c] += w * vj[c]
				}
			}
		}
	}
	a := l.o.apply(ctx, n)
	for i := range a {
		a[i] += x[i]
	}
	for t := 0; t < n; t++ {
		layerNorm(a[t*d:(t+1)*d], l.ln1g, l.ln1b)
	}
	u := l.up.apply(a, n)
	for i, z := range u {
		u[i] = float32(0.5 * float64(z) * (1 + math.Erf(float64(z)/math.Sqrt2)))
	}
	y := l.down.apply(u, n)
	for i := range y {
		y[i] += a[i]
	}
	for t := 0; t < n; t++ {
		layerNorm(y[t*d:(t+1)*d], l.ln2g, l.ln2b)
	}
	return y
}

func layerNorm(x, g, b []float32) {
	var mean, vr float64
	for _, v := range x {
		mean += float64(v)
	}
	mean /= float64(len(x))
	for _, v := range x {
		vr += (float64(v) - mean) * (float64(v) - mean)
	}
	inv := 1 / math.Sqrt(vr/float64(len(x))+1e-12)
	for i, v := range x {
		x[i] = float32((float64(v)-mean)*inv)*g[i] + b[i]
	}
}

func normalise(v []float32) {
	var s float64
	for _, x := range v {
		s += float64(x) * float64(x)
	}
	if s == 0 {
		return
	}
	inv := float32(1 / math.Sqrt(s))
	for i := range v {
		v[i] *= inv
	}
}

// dot: the sum of a[i]·b[i], eight sums at a time so the processor keeps busy.
func dot(a, b []float32) float32 {
	n := len(a)
	b = b[:n]
	var s0, s1, s2, s3, s4, s5, s6, s7 float32
	i := 0
	for ; i+8 <= n; i += 8 {
		s0 += a[i] * b[i]
		s1 += a[i+1] * b[i+1]
		s2 += a[i+2] * b[i+2]
		s3 += a[i+3] * b[i+3]
		s4 += a[i+4] * b[i+4]
		s5 += a[i+5] * b[i+5]
		s6 += a[i+6] * b[i+6]
		s7 += a[i+7] * b[i+7]
	}
	for ; i < n; i++ {
		s0 += a[i] * b[i]
	}
	return ((s0 + s1) + (s2 + s3)) + ((s4 + s5) + (s6 + s7))
}
