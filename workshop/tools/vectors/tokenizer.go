package main

// The tokenizer of MiniLM, the same as BERT's (uncased): text to the ids of its vocabulary.
// It follows the steps of Hugging Face's BertTokenizer: clean the text, put spaces around
// Chinese characters, split at spaces, lower the case and strip accents, split off each
// punctuation mark, then cut each word into the longest pieces the vocabulary has
// ("playing" is "play", "##ing"). A word it cannot cut is [UNK].

import (
	"strings"
	"unicode"

	"golang.org/x/text/unicode/norm"
)

type tokenizer struct {
	ids           map[string]int32
	unk, cls, sep int32
}

func newTokenizer(vocab []string) *tokenizer {
	t := &tokenizer{ids: make(map[string]int32, len(vocab))}
	for i, w := range vocab {
		t.ids[w] = int32(i)
	}
	t.unk, t.cls, t.sep = t.ids["[UNK]"], t.ids["[CLS]"], t.ids["[SEP]"]
	return t
}

// encode returns [CLS], the text's pieces and [SEP], at most max ids: a longer text is cut.
func (t *tokenizer) encode(text string, max int) []int32 {
	out := []int32{t.cls}
	for _, word := range words(text) {
		for _, id := range t.wordpiece(word) {
			if len(out) == max-1 {
				return append(out, t.sep)
			}
			out = append(out, id)
		}
	}
	return append(out, t.sep)
}

// words: the text cleaned, lowered, without accents, split at spaces and punctuation.
func words(text string) []string {
	var b strings.Builder
	for _, r := range text {
		switch {
		case r == 0 || r == 0xFFFD || isControl(r):
		case isSpace(r):
			b.WriteByte(' ')
		case isChinese(r):
			b.WriteByte(' ')
			b.WriteRune(r)
			b.WriteByte(' ')
		default:
			b.WriteRune(r)
		}
	}
	var out []string
	for _, w := range strings.Fields(b.String()) {
		w = stripAccents(strings.ToLower(w))
		start := 0
		rs := []rune(w)
		for i, r := range rs {
			if isPunct(r) {
				if i > start {
					out = append(out, string(rs[start:i]))
				}
				out = append(out, string(r))
				start = i + 1
			}
		}
		if start < len(rs) {
			out = append(out, string(rs[start:]))
		}
	}
	return out
}

// wordpiece cuts one word into the longest pieces in the vocabulary, left to right.
func (t *tokenizer) wordpiece(word string) []int32 {
	rs := []rune(word)
	if len(rs) > 100 {
		return []int32{t.unk}
	}
	var ids []int32
	for start := 0; start < len(rs); {
		end, found := len(rs), int32(-1)
		for ; end > start; end-- {
			s := string(rs[start:end])
			if start > 0 {
				s = "##" + s
			}
			if id, ok := t.ids[s]; ok {
				found = id
				break
			}
		}
		if found < 0 {
			return []int32{t.unk}
		}
		ids = append(ids, found)
		start = end
	}
	return ids
}

func stripAccents(s string) string {
	var b strings.Builder
	for _, r := range norm.NFD.String(s) {
		if !unicode.Is(unicode.Mn, r) {
			b.WriteRune(r)
		}
	}
	return b.String()
}

func isSpace(r rune) bool {
	return r == ' ' || r == '\t' || r == '\n' || r == '\r' || unicode.Is(unicode.Zs, r)
}

func isControl(r rune) bool {
	if r == '\t' || r == '\n' || r == '\r' {
		return false
	}
	return unicode.In(r, unicode.Cc, unicode.Cf, unicode.Co, unicode.Cs)
}

func isPunct(r rune) bool {
	if (r >= 33 && r <= 47) || (r >= 58 && r <= 64) || (r >= 91 && r <= 96) || (r >= 123 && r <= 126) {
		return true
	}
	return unicode.IsPunct(r)
}

func isChinese(r rune) bool {
	return (r >= 0x4E00 && r <= 0x9FFF) || (r >= 0x3400 && r <= 0x4DBF) ||
		(r >= 0x20000 && r <= 0x2A6DF) || (r >= 0x2A700 && r <= 0x2B73F) ||
		(r >= 0x2B740 && r <= 0x2B81F) || (r >= 0x2B820 && r <= 0x2CEAF) ||
		(r >= 0xF900 && r <= 0xFAFF) || (r >= 0x2F800 && r <= 0x2FA1F)
}
