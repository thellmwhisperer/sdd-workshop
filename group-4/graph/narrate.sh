#!/bin/sh
# The agent at work, for people: <copilot ... --output-format json> | sh graph/narrate.sh
# Copilot in JSON mode writes one event per line. This prints, as they come, what a person
# watching a colleague wants to see: what it says and what it does, each line with the time.
#   “ what it says: the first sentence of each thought (it thinks in first person before
#     each thing it does) and whatever it tells the people watching, as it streams;
#   → what it does: the plain-words description it gives each command, or the file it
#     reads, creates or edits;
#   ✗ what did not work, with the reason in one line.
# The rest of its thinking and the raw output of each command stay in the .jsonl.
# What it says is in bold, what it does is dimmed, what failed is orange: the marks tell
# them apart without the colour, and orange and blue (not red and green) are the pair a
# colour-blind person tells apart. NO_COLOR=1 prints the same without colour, for a log.
esc=$(printf '\033')
if [ -n "${NO_COLOR:-}" ]; then esc=''; fi
awk -v cwd="$(pwd)" -v esc="$esc" '
  BEGIN {
    if (esc != "") { dim = esc "[2m"; bold = esc "[1m"; orange = esc "[38;5;208m"; off = esc "[0m" }
    pad = "            "
  }
  # str <line> <key>: the first string value of "key", unescaped; \n becomes a new line.
  function str(line, key,   s, i, out, c, n) {
    i = index(line, "\"" key "\":\"")
    if (!i) return ""
    s = substr(line, i + length(key) + 4); out = ""
    while (length(s) > 0) {
      c = substr(s, 1, 1)
      if (c == "\\") {
        n = substr(s, 2, 1)
        if (n == "n") out = out "\n"; else if (n == "t") out = out " "; else out = out n
        s = substr(s, 3); continue
      }
      if (c == "\"") break
      out = out c; s = substr(s, 2)
    }
    return out
  }
  function when(line,   t) { t = str(line, "timestamp"); return substr(t, 12, 8) }
  function secs(hms) { return substr(hms, 1, 2) * 3600 + substr(hms, 4, 2) * 60 + substr(hms, 7, 2) }
  # rel <path>: a path inside the group folder, without the folder.
  function rel(p) { if (index(p, cwd "/") == 1) return substr(p, length(cwd) + 2); return p }
  # one <text> <max>: the first line, cut at max characters.
  function one(text, max,   n) {
    if (n = index(text, "\n")) text = substr(text, 1, n - 1)
    if (length(text) > max) text = substr(text, 1, max - 3) "..."
    return text
  }
  # say <label> <text>: one line. A block of talk starts after an empty line, with the time
  # and a speech mark, bold; its next lines go under it. An action is one dimmed line.
  function say(label, text) {
    gsub(/^[ \t\n]+|[ \t\n]+$/, "", text)
    if (text == "") return
    if (label == "says") {
      # Markdown marks are for a page, not a terminal: bold marks and code fences go.
      gsub(/\*\*/, "", text)
      if (text ~ /^```/) return
      sub(/:$/, ".", text)
      if (shown != label) print ""
      if (shown != label) print dim now off "  " bold "\342\200\234 " text off
      else print pad bold text off
    } else if (label == "does") {
      print dim now "  \342\206\222 " text off
    } else {
      print dim now "  " off orange "\342\234\227 " text off
    }
    shown = label
    fflush()
  }
  # flow <piece>: what it tells the people watching, printed sentence by sentence.
  function flow(piece,   i, j, cut) {
    buf = buf piece
    while (1) {
      i = index(buf, "\n")
      j = match(buf, /[.!?][ ]/) ? RSTART + 1 : 0
      cut = (i && (!j || i < j)) ? i : j
      if (!cut) break
      say("says", substr(buf, 1, cut))
      buf = substr(buf, cut + 1)
    }
  }
  function flush() { if (buf != "") say("says", buf); buf = "" }
  { now = when($0) }
  # It thinks in first person before each thing it does: the first sentence of each
  # paragraph of a thought is what it would tell a colleague. The rest is skipped.
  /"type":"assistant\.reasoning_delta"/ {
    id = str($0, "reasoningId")
    if (id != thinking) { thinking = id; head = ""; skip = 0 }
    head = head str($0, "deltaContent")
    while (1) {
      if (skip) {
        i = index(head, "\n")
        if (!i) { head = ""; break }
        head = substr(head, i + 1); skip = 0
        continue
      }
      if (match(head, /[.!?:][ \n]/)) cut = RSTART
      else if (index(head, "\n")) cut = index(head, "\n") - 1
      else if (length(head) > 220) cut = 220
      else break
      line = substr(head, 1, cut)
      # One sentence of a long thought every 20 seconds is enough to see it move.
      if (length(line) > 20 && (shown != "says" || secs(now) - secs(said_at) >= 20)) { say("says", line); said_at = now }
      head = substr(head, cut + 1); skip = 1
    }
    next
  }
  /"type":"assistant\.message_delta"/ { talked = 1; flow(str($0, "deltaContent")); next }
  /"type":"assistant\.message"/ {
    flush()
    # The end of a thought: what was left of its last paragraph is said too.
    if (!skip && length(head) > 20) say("says", one(head, 220))
    head = ""; skip = 0
    # When nothing was streamed, the whole answer comes here.
    if (!talked) { c = str($0, "content"); n = split(c, part, "\n"); for (k = 1; k <= n; k++) say("says", part[k]) }
    talked = 0
    next
  }
  /"type":"tool\.execution_start"/ {
    flush()
    tool = str($0, "toolName")
    what = str($0, "description")
    if (what == "") {
      if (tool == "view") what = "Reading " rel(str($0, "path"))
      else if (tool == "create") what = "Creating " rel(str($0, "path"))
      else if (tool == "edit") what = "Editing " rel(str($0, "path"))
      else if (tool == "bash") what = one(str($0, "command"), 120)
      else what = tool
    } else if (tool == "create" || tool == "edit" || tool == "view") what = what ": " rel(str($0, "path"))
    say("does", what)
    next
  }
  /"type":"tool\.execution_complete"/ && /"success":false/ {
    flush()
    why = str($0, "message")
    if (why ~ /^Permission denied/) why = "not allowed here: outside the group folder, or /tmp"
    sub(/^Denied by preToolUse hook: /, "not allowed: ", why)
    if (why == "") why = "that did not work"
    say("failed", one(why, 140))
  }
  END { flush() }
'
