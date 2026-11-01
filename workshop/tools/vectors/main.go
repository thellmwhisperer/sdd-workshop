// vectors: search by meaning for the workshop's memory, with a small model on this laptop.
// No server, no download, no library to install: one file for each system, and the model.
// memory/memory.sh calls it; sqlite3 keeps the pieces and their vectors.
//
//	vectors embed <model> [table]  stdin: [{"id":1,"text":"..."}] as sqlite3 -json prints
//	                               stdout: the SQL that stores each text's vector in table
//	                               (vectors when not given)
//	vectors near <model> <k> <q>   stdin: [{"id":1,"v":"<hex>"}], the stored vectors
//	                               stdout: the k pieces closest to the question, "id<TAB>score"
//	vectors events <id> <kind> <title>
//	                               stdin: a Copilot conversation, one event per line
//	                               stdout: the SQL that stores it as La Roca's corpus does:
//	                               sessions, exchanges, tool_uses, thinking_blocks (events.go)
//
// A vector is stored as 384 bytes, each number times 127. The score is the cosine: 1 is the
// same meaning, 0 nothing in common.
package main

import (
	"bufio"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"os"
	"runtime"
	"sort"
	"strconv"
	"sync"
	"time"
)

func main() {
	if len(os.Args) < 3 {
		usage()
	}
	if os.Args[1] == "events" {
		if len(os.Args) != 5 {
			usage()
		}
		events(os.Args[2], os.Args[3], os.Args[4])
		return
	}
	m, err := load(os.Args[2])
	if err != nil {
		fail(err)
	}
	switch os.Args[1] {
	case "embed":
		table := "vectors"
		if len(os.Args) > 3 {
			table = os.Args[3]
		}
		embedAll(m, table)
	case "near":
		if len(os.Args) != 5 {
			usage()
		}
		k, err := strconv.Atoi(os.Args[3])
		if err != nil || k < 1 {
			usage()
		}
		near(m, k, os.Args[4])
	default:
		usage()
	}
}

func usage() {
	fmt.Fprintln(os.Stderr, "usage: vectors embed <model> [table]   |   vectors near <model> <k> <question>   |   vectors events <session_id> <kind> <title>")
	os.Exit(2)
}

func fail(err error) {
	fmt.Fprintln(os.Stderr, "vectors:", err)
	os.Exit(1)
}

// readJSON: what sqlite3 -json printed; nothing at all when the query found no rows.
func readJSON(v any) {
	data, err := io.ReadAll(os.Stdin)
	if err != nil {
		fail(err)
	}
	if len(data) == 0 {
		return
	}
	if err := json.Unmarshal(data, v); err != nil {
		fail(fmt.Errorf("reading the pieces: %v", err))
	}
}

// embedAll: every piece's vector, on all the processor's cores, in the order they came.
func embedAll(m *model, table string) {
	var pieces []struct {
		ID   int64  `json:"id"`
		Text string `json:"text"`
	}
	readJSON(&pieces)
	vecs := make([][]float32, len(pieces))
	next, done := make(chan int), 0
	var mu sync.Mutex
	var wg sync.WaitGroup
	start := time.Now()
	for w := 0; w < runtime.NumCPU(); w++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for i := range next {
				vecs[i] = m.embed(pieces[i].Text)
				mu.Lock()
				done++
				if done%100 == 0 {
					fmt.Fprintf(os.Stderr, "  reading for meaning: %d of %d, %ds\n", done, len(pieces), int(time.Since(start).Seconds()))
				}
				mu.Unlock()
			}
		}()
	}
	for i := range pieces {
		next <- i
	}
	close(next)
	wg.Wait()
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	fmt.Fprintln(out, "BEGIN;")
	for i, p := range pieces {
		fmt.Fprintf(out, "INSERT OR REPLACE INTO %s (id, v) VALUES (%d, X'%s');\n", table, p.ID, hex.EncodeToString(bytes8(vecs[i])))
	}
	fmt.Fprintln(out, "COMMIT;")
}

func bytes8(v []float32) []byte {
	b := make([]byte, len(v))
	for i, x := range v {
		b[i] = byte(int8(math.Max(-127, math.Min(127, math.Round(float64(x)*127)))))
	}
	return b
}

// near: the k stored vectors closest to the question's.
func near(m *model, k int, question string) {
	var stored []struct {
		ID int64  `json:"id"`
		V  string `json:"v"`
	}
	readJSON(&stored)
	q := m.embed(question)
	type hit struct {
		id    int64
		score float64
	}
	var hits []hit
	for _, s := range stored {
		b, err := hex.DecodeString(s.V)
		if err != nil || len(b) != len(q) {
			continue
		}
		var d, n float64
		for i, x := range b {
			v := float64(int8(x))
			d += v * float64(q[i])
			n += v * v
		}
		if n > 0 {
			hits = append(hits, hit{s.ID, d / math.Sqrt(n)})
		}
	}
	sort.Slice(hits, func(i, j int) bool { return hits[i].score > hits[j].score })
	if len(hits) > k {
		hits = hits[:k]
	}
	for _, h := range hits {
		fmt.Printf("%d\t%.2f\n", h.id, h.score)
	}
}
