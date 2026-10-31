#!/bin/sh
# Memory for your graph: index what the runs left on disk and ask it questions.
#   sh memory/memory.sh index <folder>...   cut every text file into pieces and store them in
#                                           memory.sqlite (full-text search, SQLite FTS5)
#                                           and the vector of each piece (by meaning)
#   sh memory/memory.sh ask "<question>"    search the pieces by words and by meaning
#   sh memory/memory.sh eval "<question>"   the same question to the model, without and with
#                                           what ask finds
#   ask --raw, eval --raw                   search Copilot's raw events instead
# Everything a run leaves is kept. Each run step's copilot.jsonl is Copilot's raw event
# stream, most of what a run writes and hard to read; ask and eval leave it out unless
# you say --raw, and ask tells you how many raw pieces also matched.
# By words: SQLite ranks the pieces that hold every word that carries meaning (bm25).
# By meaning: a small model on this laptop, MiniLM (minilm.bin, 23 MB), turns each piece
# and the question into a vector of 384 numbers; the closest vectors mean the most alike,
# even with other words. bin/vectors-darwin-<arch> runs the model, on a Mac for now; its
# code is in workshop/tools/vectors. Raw events are searched by words only.
# Indexing a folder again replaces only that folder's pieces, so your runs sit next to the
# example team's. Needs sqlite3; eval also needs copilot.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
db="$here/memory.sqlite"
piece=800 # bytes per piece, about 800 letters of English: small enough to be about one thing

command -v sqlite3 > /dev/null 2>&1 || { printf 'sqlite3 not found: install SQLite 3 with FTS5\n' >&2; exit 1; }

# sql_quote: stdin as an SQL string literal, its quotes doubled.
sql_quote() { sed "s/'/''/g; 1s/^/'/; \$s/\$/'/"; }

# pieces <file> <source>: the INSERT statements of the file's pieces. Paragraphs (split at
# blank lines; in a .jsonl file each line, one event) go on a piece while it stays under
# 800 bytes; a paragraph longer than two pieces is cut every 800 bytes, never inside a
# letter: awk counts bytes here on every system, and a letter such as € takes three.
pieces() {
  case $1 in *.jsonl) each=1 ;; *) each=0 ;; esac
  LC_ALL=C awk -v src="$2" -v max="$piece" -v each="$each" '
    BEGIN { for (i = 128; i < 192; i++) inside[sprintf("%c", i)] = 1 }
    function q(s) { gsub(/\047/, "\047\047", s); return "\047" s "\047" }
    function cut(s, k) { while (k > 1 && substr(s, k + 1, 1) in inside) k--; return k }
    function out(s) { printf "INSERT INTO pieces (source, text) VALUES (%s, %s);\n", q(src), q(s); n++ }
    function para(p) {
      if (cur != "" && length(cur) + length(p) > max) { out(cur); cur = "" }
      cur = cur (cur == "" ? "" : "\n\n") p
      while (length(cur) > max * 2) { k = cut(cur, max); out(substr(cur, 1, k)); cur = substr(cur, k + 1) }
    }
    /^[ \t\r]*$/ { if (p != "") para(p); p = ""; next }
    each { para($0); next }
    { p = p (p == "" ? "" : "\n") $0 }
    END { if (p != "") para(p); if (cur ~ /[^ \t\r\n]/) out(cur) }' "$1"
}

index_folders() {
  {
    printf 'CREATE VIRTUAL TABLE IF NOT EXISTS pieces USING fts5(source, text);\n'
    printf 'CREATE TABLE IF NOT EXISTS vectors (id INTEGER PRIMARY KEY, v BLOB);\nBEGIN;\n'
    for folder in "$@"; do
      [ -d "$folder" ] || { printf 'no folder: %s\n' "$folder" >&2; continue; }
      full=$(cd "$folder" && pwd)
      name=$(basename "$full")
      like=$(printf '%s/%%' "$name" | sql_quote)
      printf 'DELETE FROM vectors WHERE id IN (SELECT rowid FROM pieces WHERE source LIKE %s);\n' "$like"
      printf 'DELETE FROM pieces WHERE source LIKE %s;\n' "$like"
      # What a run leaves that is not its story: the clone of the repository it worked on.
      (cd "$full" && find . \( -name workspace -o -name node_modules -o -name .git \) -prune -o -type f \
        \( -name '*.md' -o -name '*.txt' -o -name '*.log' -o -name '*.tsv' -o -name '*.json' \
        -o -name '*.jsonl' -o -name '*.yaml' -o -name '*.yml' \) -print) | sort | while read -r f; do
        pieces "$full/${f#./}" "$name/${f#./}"
      done
    done
    printf 'COMMIT;\n'
  } > "$here/.index.sql"
  sqlite3 "$db" < "$here/.index.sql"
  n=$(grep -c '^INSERT' "$here/.index.sql" || true)
  rm -f "$here/.index.sql"
  printf '%s pieces: text in memory.sqlite\n' "$n"
  embed_missing
}

# vectors_program: this system's bin/vectors-<os>-<arch>, or nothing when there is none.
vectors_program() {
  case $(uname -s) in
    Darwin) vp_os=darwin ;;
    Linux) vp_os=linux ;;
    MINGW* | MSYS* | CYGWIN*) vp_os=windows ;;
    *) return 0 ;;
  esac
  case $(uname -m) in
    arm64 | aarch64) vp_arch=arm64 ;;
    x86_64 | amd64) vp_arch=amd64 ;;
    *) return 0 ;;
  esac
  vp="$here/bin/vectors-$vp_os-$vp_arch"
  if [ "$vp_os" = windows ]; then vp="$vp.exe"; fi
  [ -f "$vp" ] && [ -f "$here/minilm.bin" ] || return 0
  [ -x "$vp" ] || chmod +x "$vp" 2> /dev/null || true
  printf '%s\n' "$vp"
}

# embed_missing: the vector of every piece that has none yet; raw events have none.
embed_missing() {
  vp=$(vectors_program)
  if [ -z "$vp" ]; then
    printf 'by meaning: no vectors program for this system (%s %s); ask searches by words only\n' "$(uname -s)" "$(uname -m)"
    return 0
  fi
  sqlite3 -json "$db" "SELECT rowid AS id, text FROM pieces WHERE source NOT LIKE '%copilot.jsonl'
    AND rowid NOT IN (SELECT id FROM vectors);" > "$here/.embed.json"
  "$vp" embed "$here/minilm.bin" < "$here/.embed.json" > "$here/.vectors.sql"
  sqlite3 "$db" < "$here/.vectors.sql"
  n=$(grep -c '^INSERT' "$here/.vectors.sql" || true)
  rm -f "$here/.embed.json" "$here/.vectors.sql"
  printf '%s pieces by meaning: their vectors in memory.sqlite\n' "$n"
}

# meaning <question>: the 3 pieces closest in meaning, "source<TAB>text<TAB>score" each.
meaning() {
  vp=$(vectors_program)
  [ -n "$vp" ] || return 0
  has=$(sqlite3 -readonly "$db" "SELECT count(*) FROM sqlite_master WHERE name = 'vectors';")
  [ "$has" = 1 ] || return 0
  sqlite3 -readonly -json "$db" "SELECT id, hex(v) AS v FROM vectors;" > "$here/.near.json"
  closest=$("$vp" near "$here/minilm.bin" 3 "$1" < "$here/.near.json")
  rm -f "$here/.near.json"
  printf '%s\n' "$closest" | while read -r id score; do
    [ -n "$id" ] || continue
    sqlite3 -readonly -batch -noheader -list "$db" \
      "SELECT source || char(9) || replace(replace(replace(text, char(13), ' '), char(10), ' '), char(9), ' ')
       || char(9) || '$score' FROM pieces WHERE rowid = $id;"
  done
}

# search <question>: the best 3 pieces by words, one "source<TAB>text" line each, the text on
# one line. Like any search box: every word that carries meaning must appear, as written.
# Leaves out Copilot's raw events, or searches only them when raw=yes. search <question>
# raw-count prints instead how many of Copilot's raw events match.
raw=no
search() {
  s_raw=$raw s_count=no
  if [ "${2:-}" = raw-count ]; then s_raw=yes s_count=yes; fi
  words=$(printf '%s\n' "$1" | awk '
    BEGIN {
      n = split("a an and are as at be but by can did do does for from had has have how i in is it its " \
        "me my no not of on or our so t that the their them there they this to was we were what when where which " \
        "who why will with you your", s, " ")
      for (i = 1; i <= n; i++) stop[s[i]] = 1
    }
    { $0 = tolower($0); gsub(/[^[:alnum:]]+/, " ")
      for (i = 1; i <= NF; i++) if (!($i in stop)) printf "%s\"%s\"", (out++ ? " " : ""), $i }')
  [ -n "$words" ] || return 0
  which=NOT
  if [ "$s_raw" = yes ]; then which=''; fi
  where="pieces MATCH $(printf '%s' "$words" | sql_quote) AND source $which LIKE '%copilot.jsonl'"
  if [ "$s_count" = yes ]; then
    sqlite3 -readonly -batch -noheader -list "$db" "SELECT count(*) FROM pieces WHERE $where;"
    return 0
  fi
  sqlite3 -readonly -batch -noheader -list "$db" \
    "SELECT source || char(9) || replace(replace(replace(text, char(13), ' '), char(10), ' '), char(9), ' ')
     FROM pieces WHERE $where ORDER BY bm25(pieces) LIMIT 3;"
}

ask() {
  found=$(search "$1")
  if [ "$raw" = yes ]; then
    printf "BY WORDS (full-text search), in Copilot's raw events only:\n"
  else
    printf "BY WORDS (full-text search), Copilot's raw events left out:\n"
  fi
  if [ -z "$found" ]; then
    printf '  nothing found\n'
  else
    printf '%s\n' "$found" | awk -F '\t' '{ t = $2; gsub(/[ ]+/, " ", t); printf "  %d. %s\n     %s\n", NR, $1, substr(t, 1, 160) }'
  fi
  if [ "$raw" = no ]; then
    others=$(search "$1" raw-count)
    if [ "${others:-0}" -gt 0 ]; then
      printf "  Also %s pieces in Copilot's raw events: sh memory/memory.sh ask --raw \"%s\"\n" "$others" "$1"
    fi
  fi
  printf '\n'
  if [ "$raw" = yes ]; then
    printf "BY MEANING (vectors): Copilot's raw events are searched by words only.\n"
  elif [ -z "$(vectors_program)" ]; then
    printf 'BY MEANING (vectors): no vectors program for this system (%s %s).\n' "$(uname -s)" "$(uname -m)"
  else
    printf "BY MEANING (vectors, MiniLM on this laptop), Copilot's raw events left out:\n"
    close=$(meaning "$1")
    if [ -z "$close" ]; then
      printf '  nothing indexed by meaning yet: sh memory/memory.sh index <folder>\n'
    else
      printf '%s\n' "$close" | awk -F '\t' '{ t = $2; gsub(/[ ]+/, " ", t); printf "  %d. %s (%s)\n     %s\n", NR, $1, $3, substr(t, 1, 160) }'
    fi
  fi
}

# model <prompt>: the model's answer. Copilot CLI answers with no tools, from an empty folder,
# so the only memory it gets is what we pass.
model() {
  command -v copilot > /dev/null 2>&1 || { printf 'copilot not found: install the GitHub Copilot CLI\n' >&2; exit 1; }
  empty="$here/.empty"
  mkdir -p "$empty"
  copilot -p "$1" -s --no-custom-instructions --disable-builtin-mcps --available-tools=none \
    --disallow-temp-dir -C "$empty" 2>&1 || true
}

# evaluate <question>: the same question to the model twice: alone, and with what ask found.
evaluate() {
  found=$(search "$1")
  if [ "$raw" = no ]; then
    found=$( {
      meaning "$1" | cut -f 1,2
      if [ -n "$found" ]; then printf '%s\n' "$found"; fi
    } | awk '!seen[$0]++')
  fi
  rule='Do not use any tools. Answer in at most three sentences. If you do not know, say so.'
  printf 'WITHOUT RETRIEVAL:\n%s\n\n' "$(model "$rule

Question: $1")"
  if [ -n "$found" ]; then
    count=$(printf '%s\n' "$found" | grep -c '' || true)
    sources=$(printf '%s\n' "$found" | cut -f 1 | awk '{ printf "%s%s", (NR > 1 ? ", " : ""), $0 }')
    notes=$(printf '%s\n' "$found" | awk -F '\t' '{ printf "%s[%s]\n%s\n", (NR > 1 ? "\n" : ""), $1, $2 }')
  else
    count=0 sources='' notes=''
  fi
  printf 'WITH RETRIEVAL (%s pieces: %s):\n' "$count" "$sources"
  printf '%s\n' "$(model "$rule Answer only from these notes of the team's history, and name the note you used.

$notes

Question: $1")"
}

command=${1:-}
[ $# -eq 0 ] || shift
# One line per command in memory.log: the workshop status reads it to know the group's step.
case $command in
  index | ask | eval) if [ $# -gt 0 ]; then printf '%s\t%s\n' "$command" "$*" >> "$here/memory.log"; fi ;;
esac
case $command in
  ask | eval) if [ "${1:-}" = --raw ]; then raw=yes; shift; fi ;;
esac
if [ "$command" = index ] && [ $# -gt 0 ]; then
  index_folders "$@"
elif [ "$command" = ask ] && [ $# -gt 0 ]; then
  ask "$*"
elif [ "$command" = eval ] && [ $# -gt 0 ]; then
  evaluate "$*"
else
  printf 'Usage: sh memory/memory.sh index <folder>...   |   sh memory/memory.sh ask [--raw] "<question>"   |   sh memory/memory.sh eval [--raw] "<question>"\n'
fi
