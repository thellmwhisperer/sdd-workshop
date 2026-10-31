#!/bin/sh
# Memory for your graph: index what the runs left on disk and ask it questions.
#   sh memory/memory.sh index <folder>...   cut every text file into pieces and store them in
#                                           memory.sqlite (full-text search, SQLite FTS5)
#   sh memory/memory.sh ask "<question>"    search the pieces by words
#   sh memory/memory.sh eval "<question>"   the same question to the model, without and with
#                                           what ask finds
# By words today: SQLite ranks the pieces that hold every word that carries meaning (bm25).
# By meaning (vectors) needs a model runtime, and this tool is shell only.
# Indexing a folder again replaces only that folder's pieces, so your runs sit next to the
# example team's. Needs sqlite3; eval also needs copilot.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
db="$here/memory.sqlite"
piece=800 # characters per piece: small enough to be about one thing

command -v sqlite3 > /dev/null 2>&1 || { printf 'sqlite3 not found: install SQLite 3 with FTS5\n' >&2; exit 1; }

# sql_quote: stdin as an SQL string literal, its quotes doubled.
sql_quote() { sed "s/'/''/g; 1s/^/'/; \$s/\$/'/"; }

# pieces <file> <source>: the INSERT statements of the file's pieces. Paragraphs (split at
# blank lines) go on a piece while it stays under 800 characters; a paragraph longer than
# two pieces is cut every 800 characters.
pieces() {
  awk -v src="$2" -v max="$piece" '
    function q(s) { gsub(/\047/, "\047\047", s); return "\047" s "\047" }
    function out(s) { printf "INSERT INTO pieces (source, text) VALUES (%s, %s);\n", q(src), q(s); n++ }
    function para(p) {
      if (cur != "" && length(cur) + length(p) > max) { out(cur); cur = "" }
      cur = cur (cur == "" ? "" : "\n\n") p
      while (length(cur) > max * 2) { out(substr(cur, 1, max)); cur = substr(cur, max + 1) }
    }
    /^[ \t\r]*$/ { if (p != "") para(p); p = ""; next }
    { p = p (p == "" ? "" : "\n") $0 }
    END { if (p != "") para(p); if (cur ~ /[^ \t\r\n]/) out(cur) }' "$1"
}

index_folders() {
  {
    printf 'CREATE VIRTUAL TABLE IF NOT EXISTS pieces USING fts5(source, text);\nBEGIN;\n'
    for folder in "$@"; do
      [ -d "$folder" ] || { printf 'no folder: %s\n' "$folder" >&2; continue; }
      full=$(cd "$folder" && pwd)
      name=$(basename "$full")
      printf "DELETE FROM pieces WHERE source LIKE %s;\n" "$(printf '%s/%%' "$name" | sql_quote)"
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
}

# search <question>: the best 3 pieces by words, one "source<TAB>text" line each, the text on
# one line. Like any search box: every word that carries meaning must appear, as written.
search() {
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
  sqlite3 -readonly -batch -noheader -list "$db" \
    "SELECT source || char(9) || replace(replace(replace(text, char(13), ' '), char(10), ' '), char(9), ' ')
     FROM pieces WHERE pieces MATCH $(printf '%s' "$words" | sql_quote) ORDER BY bm25(pieces) LIMIT 3;"
}

ask() {
  found=$(search "$1")
  printf 'BY WORDS (full-text search):\n'
  if [ -z "$found" ]; then
    printf '  nothing found\n'
  else
    printf '%s\n' "$found" | awk -F '\t' '{ t = $2; gsub(/[ ]+/, " ", t); printf "  %d. %s\n     %s\n", NR, $1, substr(t, 1, 160) }'
  fi
  printf '\nBY MEANING (vectors): not in this version; search by meaning needs a model runtime.\n'
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
if [ "$command" = index ] && [ $# -gt 0 ]; then
  index_folders "$@"
elif [ "$command" = ask ] && [ $# -gt 0 ]; then
  ask "$*"
elif [ "$command" = eval ] && [ $# -gt 0 ]; then
  evaluate "$*"
else
  printf 'Usage: sh memory/memory.sh index <folder>...   |   sh memory/memory.sh ask "<question>"   |   sh memory/memory.sh eval "<question>"\n'
fi
