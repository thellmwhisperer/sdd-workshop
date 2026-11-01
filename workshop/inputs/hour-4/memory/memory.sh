#!/bin/sh
# Memory for your graph: index what the runs left on disk and ask it questions.
#   sh memory/memory.sh index <folder>...   cut every text file into pieces and store them,
#                                           with their vectors (by meaning)
#   sh memory/memory.sh ask "<question>"    search the pieces by words and by meaning
#   sh memory/memory.sh eval "<question>"   the same question to the model, without and with
#                                           what ask finds
#   ask --raw, eval --raw                   search what is left out: Copilot's raw events and
#                                           the tools the agents used
# Two indexes, so neither buries the other: example-team.sqlite holds the example team,
# given; group.sqlite holds what you index, your runs and your notes. ask answers from each.
# A conversation is kept by who speaks, one turn per piece, the speaker in its own field:
# in the example team, "Ines:" or "Chief:"; in a run's conversation.md, User (the graph's
# brief) and Copilot (the agent), and tool for each tool the agent called with what it
# returned, such as a file it read. Everything a run leaves is kept. Tool turns and
# copilot.jsonl, Copilot's raw event stream, stay out of the answers unless you say --raw,
# and ask tells you how many of them also matched.
# By words: SQLite full-text search (FTS5) ranks the pieces that hold every word that
# carries meaning (bm25), in the text only, never in the file's path.
# By meaning: a small model on this laptop, MiniLM (minilm.bin, 23 MB), turns each piece
# and the question into a vector of 384 numbers; the closest vectors mean the most alike,
# even with other words. bin/vectors-darwin-<arch> runs the model, on a Mac for now; its
# code is in workshop/tools/vectors. What is left out is searched by words only.
# Indexing a folder again replaces only that folder's pieces. Needs sqlite3; eval also
# needs copilot.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
example_db="$here/example-team.sqlite"
group_db="$here/group.sqlite"
piece=800 # bytes per piece, about 800 letters of English: small enough to be about one thing
out="who NOT IN ('raw', 'tool')" # what ask and eval search, unless --raw

command -v sqlite3 > /dev/null 2>&1 || { printf 'sqlite3 not found: install SQLite 3 with FTS5\n' >&2; exit 1; }

# sql_quote: stdin as an SQL string literal, its quotes doubled.
sql_quote() { sed "s/'/''/g; 1s/^/'/; \$s/\$/'/"; }

# pieces <file> <source>: the INSERT statements of the file's pieces, each with who speaks.
# A conversation.md (Copilot's export of one agent step) is cut at its turns: "### User",
# "### Copilot", and "### `tool`" for a tool call and what it returned. A file of the
# example team's conversations is cut where the speaker ("Ines:") changes; its title, with
# the date, goes on every turn. Any other file has no speaker: paragraphs (split at blank
# lines; in a .jsonl file each line, one event, who is raw for copilot.jsonl). A piece
# never mixes two turns; it grows while it stays under 800 bytes, and a paragraph longer
# than two pieces is cut every 800 bytes, never inside a letter: awk counts bytes here on
# every system, and a letter such as € takes three.
pieces() {
  case $1 in
    */conversation.md) mode=turns ;;
    */conversations/*.md) mode=speakers ;;
    *) mode=plain ;;
  esac
  case $1 in */copilot.jsonl) who=raw ;; *) who='' ;; esac
  case $1 in *.jsonl) each=1 ;; *) each=0 ;; esac
  LC_ALL=C awk -v src="$2" -v max="$piece" -v each="$each" -v mode="$mode" -v who="$who" '
    BEGIN { for (i = 128; i < 192; i++) inside[sprintf("%c", i)] = 1; started = mode == "plain" }
    function q(s) { gsub(/\047/, "\047\047", s); return "\047" s "\047" }
    function cut(s, k) { while (k > 1 && substr(s, k + 1, 1) in inside) k--; return k }
    function out(s) {
      if (s !~ /[^ \t\r\n]/) return
      if (title != "") s = title "\n" s
      printf "INSERT INTO pieces (source, who, text) VALUES (%s, %s, %s);\n", q(src), q(who), q(s)
    }
    function para(p) {
      if (cur != "" && length(cur) + length(p) > max) { out(cur); cur = "" }
      cur = cur (cur == "" ? "" : "\n\n") p
      while (length(cur) > max * 2) { k = cut(cur, max); out(substr(cur, 1, k)); cur = substr(cur, k + 1) }
    }
    function turn(next_who) { if (p != "") para(p); p = ""; out(cur); cur = ""; who = next_who; started = 1 }
    mode == "turns" && /^### User[ \t\r]*$/ { turn("User"); next }
    mode == "turns" && /^### Copilot[ \t\r]*$/ { turn("Copilot"); next }
    mode == "turns" && /^### `[^`]+`/ { turn("tool"); next }
    mode == "turns" && (/^<sub>[^<]*<\/sub>[ \t\r]*$/ || /^---[ \t\r]*$/) { next }
    mode == "speakers" && title == "" && /^# / { title = $0; next }
    mode == "speakers" && /^[A-Z][A-Za-z]*: / {
      s = substr($0, 1, index($0, ":") - 1)
      if (s != who) turn(s)
    }
    !started { next }
    /^[ \t\r]*$/ { if (p != "") para(p); p = ""; next }
    each { para($0); next }
    { p = p (p == "" ? "" : "\n") $0 }
    END { if (p != "") para(p); out(cur) }' "$1"
}

# db_of <folder>: the index a folder goes to: the example team's, or the group's.
db_of() { if [ "$(basename "$1")" = example-team ]; then printf '%s\n' "$example_db"; else printf '%s\n' "$group_db"; fi; }

index_folders() {
  for folder in "$@"; do
    [ -d "$folder" ] || { printf 'no folder: %s\n' "$folder" >&2; continue; }
    full=$(cd "$folder" && pwd)
    name=$(basename "$full")
    db=$(db_of "$full")
    like=$(printf '%s/%%' "$name" | sql_quote)
    {
      printf 'CREATE VIRTUAL TABLE IF NOT EXISTS pieces USING fts5(source UNINDEXED, who UNINDEXED, text);\n'
      printf 'CREATE TABLE IF NOT EXISTS vectors (id INTEGER PRIMARY KEY, v BLOB);\nBEGIN;\n'
      printf 'DELETE FROM vectors WHERE id IN (SELECT rowid FROM pieces WHERE source LIKE %s);\n' "$like"
      printf 'DELETE FROM pieces WHERE source LIKE %s;\n' "$like"
      # What a run leaves that is not its story: the clone of the repository it worked on.
      (cd "$full" && find . \( -name workspace -o -name node_modules -o -name .git \) -prune -o -type f \
        \( -name '*.md' -o -name '*.txt' -o -name '*.log' -o -name '*.tsv' -o -name '*.json' \
        -o -name '*.jsonl' -o -name '*.yaml' -o -name '*.yml' \) -print) | sort | while read -r f; do
        pieces "$full/${f#./}" "$name/${f#./}"
      done
      printf 'COMMIT;\n'
    } > "$here/.index.sql"
    sqlite3 "$db" < "$here/.index.sql"
    n=$(grep -c '^INSERT' "$here/.index.sql" || true)
    rm -f "$here/.index.sql"
    printf '%s: %s pieces in %s\n' "$name" "$n" "$(basename "$db")"
    embed_missing "$db"
  done
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

# embed_missing <db>: the vector of every piece that has none yet; what is left out has none.
embed_missing() {
  vp=$(vectors_program)
  if [ -z "$vp" ]; then
    printf 'by meaning: no vectors program for this system (%s %s); ask searches by words only\n' "$(uname -s)" "$(uname -m)"
    return 0
  fi
  sqlite3 -json "$1" "SELECT rowid AS id, text FROM pieces WHERE $out
    AND rowid NOT IN (SELECT id FROM vectors);" > "$here/.embed.json"
  "$vp" embed "$here/minilm.bin" < "$here/.embed.json" > "$here/.vectors.sql"
  sqlite3 "$1" < "$here/.vectors.sql"
  n=$(grep -c '^INSERT' "$here/.vectors.sql" || true)
  rm -f "$here/.embed.json" "$here/.vectors.sql"
  printf '%s pieces by meaning: their vectors in %s\n' "$n" "$(basename "$1")"
}

# indexed <db>: true when the db has pieces.
indexed() { [ -f "$1" ] && [ "$(sqlite3 -readonly "$1" "SELECT count(*) FROM sqlite_master WHERE name = 'pieces';")" = 1 ]; }

# rows <db> <where>: "source<TAB>who<TAB>text" of the matching pieces, the text on one line.
rows() {
  sqlite3 -readonly -batch -noheader -list "$1" \
    "SELECT source || char(9) || who || char(9) || replace(replace(replace(text, char(13), ' '), char(10), ' '), char(9), ' ')
     FROM pieces WHERE $2;"
}

# meaning <db> <question>: the 3 pieces closest in meaning, "source<TAB>who<TAB>text<TAB>score" each.
meaning() {
  vp=$(vectors_program)
  [ -n "$vp" ] || return 0
  has=$(sqlite3 -readonly "$1" "SELECT count(*) FROM sqlite_master WHERE name = 'vectors';")
  [ "$has" = 1 ] || return 0
  sqlite3 -readonly -json "$1" "SELECT id, hex(v) AS v FROM vectors;" > "$here/.near.json"
  closest=$("$vp" near "$here/minilm.bin" 3 "$2" < "$here/.near.json")
  rm -f "$here/.near.json"
  printf '%s\n' "$closest" | while read -r id score; do
    [ -n "$id" ] || continue
    printf '%s\t%s\n' "$(rows "$1" "rowid = $id")" "$score"
  done
}

# search <db> <question>: the best 3 pieces by words, "source<TAB>who<TAB>text" each. Like
# any search box: every word that carries meaning must appear, as written. Searches what
# ask shows, or only what is left out when raw=yes. search <db> <question> left-count prints
# instead how many of the left-out pieces match.
raw=no
search() {
  s_raw=$raw s_count=no
  if [ "${3:-}" = left-count ]; then s_raw=yes s_count=yes; fi
  words=$(printf '%s\n' "$2" | awk '
    BEGIN {
      n = split("a an and are as at be but by can did do does for from had has have how i in is it its " \
        "me my no not of on or our so t that the their them there they this to was we were what when where which " \
        "who why will with you your", s, " ")
      for (i = 1; i <= n; i++) stop[s[i]] = 1
    }
    { $0 = tolower($0); gsub(/[^[:alnum:]]+/, " ")
      for (i = 1; i <= NF; i++) if (!($i in stop)) printf "%s\"%s\"", (out++ ? " " : ""), $i }')
  [ -n "$words" ] || return 0
  which=$out
  if [ "$s_raw" = yes ]; then which="NOT ($out)"; fi
  where="pieces MATCH $(printf '%s' "$words" | sql_quote) AND $which"
  if [ "$s_count" = yes ]; then
    sqlite3 -readonly -batch -noheader -list "$1" "SELECT count(*) FROM pieces WHERE $where;"
    return 0
  fi
  rows "$1" "$where ORDER BY bm25(pieces) LIMIT 3"
}

# show: the found lines, numbered, each with its source and who speaks.
show() {
  awk -F '\t' '{ t = $3; gsub(/[ ]+/, " ", t); w = ($2 == "" ? "" : " · " $2); s = ($4 == "" ? "" : " (" $4 ")")
    printf "    %d. %s%s%s\n       %s\n", NR, $1, w, s, substr(t, 1, 160) }'
}

# ask_one <db> <title> <question>: what one index answers.
ask_one() {
  printf '%s\n' "$2"
  if ! indexed "$1"; then
    printf '  nothing indexed yet: sh memory/memory.sh index graph/runs notes\n\n'
    return 0
  fi
  found=$(search "$1" "$3")
  if [ "$raw" = yes ]; then
    printf "  BY WORDS (full-text search), only what is left out: Copilot's raw events and tool turns:\n"
  else
    printf "  BY WORDS (full-text search), Copilot's raw events and tool turns left out:\n"
  fi
  if [ -z "$found" ]; then printf '    nothing found\n'; else printf '%s\n' "$found" | show; fi
  if [ "$raw" = no ]; then
    others=$(search "$1" "$3" left-count)
    if [ "${others:-0}" -gt 0 ]; then
      printf "    Also %s left-out pieces: sh memory/memory.sh ask --raw \"%s\"\n" "$others" "$3"
    fi
  fi
  if [ "$raw" = yes ]; then
    printf "  BY MEANING (vectors): what is left out is searched by words only.\n"
  elif [ -z "$(vectors_program)" ]; then
    printf '  BY MEANING (vectors): no vectors program for this system (%s %s).\n' "$(uname -s)" "$(uname -m)"
  else
    printf "  BY MEANING (vectors, MiniLM on this laptop), Copilot's raw events and tool turns left out:\n"
    close=$(meaning "$1" "$3")
    if [ -z "$close" ]; then printf '    nothing indexed by meaning yet\n'; else printf '%s\n' "$close" | show; fi
  fi
  printf '\n'
}

ask() {
  ask_one "$example_db" 'THE EXAMPLE TEAM (example-team.sqlite):' "$1"
  ask_one "$group_db" 'YOUR RUNS AND NOTES (group.sqlite):' "$1"
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

# evaluate <question>: the same question to the model twice: alone, and with what ask found
# in both indexes.
evaluate() {
  found=$(for db in "$example_db" "$group_db"; do
    indexed "$db" || continue
    if [ "$raw" = no ]; then meaning "$db" "$1" | cut -f 1-3; fi
    search "$db" "$1"
  done | awk 'NF && !seen[$0]++')
  rule='Do not use any tools. Answer in at most three sentences. If you do not know, say so.'
  printf 'WITHOUT RETRIEVAL:\n%s\n\n' "$(model "$rule

Question: $1")"
  if [ -n "$found" ]; then
    count=$(printf '%s\n' "$found" | grep -c '' || true)
    sources=$(printf '%s\n' "$found" | cut -f 1 | awk '{ printf "%s%s", (NR > 1 ? ", " : ""), $0 }')
    notes=$(printf '%s\n' "$found" | awk -F '\t' '{ printf "%s[%s%s]\n%s\n", (NR > 1 ? "\n" : ""), $1, ($2 == "" ? "" : ", " $2 " said"), $3 }')
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
