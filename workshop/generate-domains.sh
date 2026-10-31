#!/bin/sh
# Generates workshop/domains/<slug>/ of the workshop repository: DOMAIN.md with open
# decisions, and the hour 1 base (decisions taken, the product's OpenSpec change, tickets
# 001-003).
# Usage: sh workshop/generate-domains.sh <repository root>
#
# The domains are the data block at the end, one line per item, tab-separated:
#   domain <slug> | product, change, cap, brief, story, goal <text> | fact <text>
#   decision <title> <the question> <what the group chose> <what we know>
#   req <title> <text> | scenario <title> <when> <then> (of the req above it)
#   ticket <file name> <title> <test name> | end (writes the domain)
set -eu
root=${1:?usage: sh workshop/generate-domains.sh <repository root>}

# Bytes, not characters: the awk is told so (LC_ALL=C), and counts characters itself.
LC_ALL=C awk -F '\t' -v root="$root" '
  # clen <text>: its length in characters (UTF-8: the bytes that do not continue a character).
  function clen(s,   i, n, c) {
    n = 0
    for (i = 1; i <= length(s); i++) { c = substr(s, i, 1); if (c < "\200" || c > "\277") n++ }
    return n
  }
  function isletter(c) { return c ~ /^[A-Za-z]$/ || c > "\177" }
  # hyphen_ok <word> <k>: the word may break after its hyphen at k (Python textwrap: two
  # letters before it, or letter-hyphen-letter, and a letter after it).
  function hyphen_ok(w, k,   b1, b2, b3, a1, a2, a3) {
    b1 = substr(w, k - 1, 1); b2 = substr(w, k - 2, 1); b3 = substr(w, k - 3, 1)
    a1 = substr(w, k + 1, 1); a2 = substr(w, k + 2, 1); a3 = substr(w, k + 3, 1)
    if (k < 3 || !isletter(b1)) return 0
    if (!(isletter(b2) || (b2 == "-" && k >= 4 && isletter(b3)))) return 0
    return isletter(a1) && (isletter(a2) || (a2 == "-" && isletter(a3)))
  }
  # chunkify <text>: cuts it into ch[1..n]: runs of spaces, and words cut after their hyphens.
  function chunkify(text,   n, i, j, k, L, w, start) {
    split("", ch)
    gsub(/[\t\n\r\f\v]/, " ", text)
    n = 0; i = 1; L = length(text)
    while (i <= L) {
      j = i
      if (substr(text, i, 1) == " ") {
        while (j <= L && substr(text, j, 1) == " ") j++
        ch[++n] = substr(text, i, j - i); i = j; continue
      }
      while (j <= L && substr(text, j, 1) != " ") j++
      w = substr(text, i, j - i); start = 1
      for (k = 2; k < length(w); k++) {
        if (substr(w, k, 1) != "-" || k <= start || !hyphen_ok(w, k)) continue
        ch[++n] = substr(w, start, k - start + 1); start = k + 1
      }
      ch[++n] = substr(w, start)
      i = j
    }
    return n
  }
  # fill <text> <first indent> <next indent>: Python textwrap.fill at 90 columns, the wrap these
  # files were written with: words go on a line while they fit, a hyphenated word may break
  # after its hyphen, and the spaces at the ends of lines are dropped.
  function fill(text, initial, subsequent,   n, k, out, nl, cur, curlen, indent, room, l, last, left) {
    n = chunkify(text); k = 1; out = ""; nl = 0
    while (k <= n) {
      indent = nl ? subsequent : initial
      room = 90 - clen(indent)
      if (nl && ch[k] ~ /^ +$/) k++
      cur = ""; curlen = 0; last = ""
      while (k <= n) {
        l = clen(ch[k])
        if (curlen + l > room) break
        cur = cur ch[k]; curlen += l; last = ch[k]; k++
      }
      if (k <= n && clen(ch[k]) > room) { # a word longer than a line: cut it
        left = room - curlen; if (left < 1) left = 1
        cur = cur substr(ch[k], 1, left); last = substr(ch[k], 1, left); ch[k] = substr(ch[k], left + 1)
      }
      if (cur != "" && last ~ /^ +$/) cur = substr(cur, 1, length(cur) - length(last))
      if (cur != "") { out = out (nl ? "\n" : "") indent cur; nl++ }
    }
    return out
  }
  function pad(i) { return sprintf("%03d", i) }
  # write <path> <text>: the file, with its folders; leading blank lines dropped.
  function write(path, text,   dir) {
    dir = path; sub(/\/[^\/]*$/, "", dir)
    system("mkdir -p \"" dir "\"")
    sub(/^\n+/, "", text)
    printf "%s", text > path
    close(path)
  }
  function domain_md(decided,   out, i) {
    out = "# Product: " product "\n\n## The client\047s brief\n\n" fill(brief) "\n\n## The story\n\n" fill(story) "\n\n"
    out = out "## What we know about the business\n\n"
    for (i = 1; i <= nf; i++) out = out (i > 1 ? "\n" : "") fill(fact[i], "- ", "  ")
    out = out "\n\n## The goal\n\n" fill(goal) "\n\n## Open decisions\n\n"
    out = out "The group decides each one with the chief. The chief writes the decision below it.\n"
    for (i = 1; i <= nd; i++) {
      out = out "\n### " i ". " dtitle[i] "\n\n" fill(dtext[i]) "\n\n" fill("What we know: " dknown[i]) "\n\n"
      out = out "**Decision:** " (decided ? dchoice[i] : "_pending_") "\n"
    }
    return out
  }
  function generate(   base, h1, ch_dir, reqs, spec, i, s, tasks, accept, before, j, t) {
    base = root "/workshop/domains/" slug
    write(base "/DOMAIN.md", domain_md(0))
    h1 = base "/hour-1"
    write(h1 "/DOMAIN.md", domain_md(1))
    ch_dir = h1 "/openspec/changes/" change
    reqs = ""
    for (i = 1; i <= nr; i++) reqs = reqs (i > 1 ? "\n" : "") "- " rtitle[i] "."
    write(ch_dir "/proposal.md", "## Why\n\n" fill(brief) "\n\nProof: the app in `app/` is a single page with the product name; none of this exists.\n\n## What Changes\n\n" reqs "\n\n## Capabilities\n\n### New Capabilities\n- `" cap "`: " tolower(product) ", as decided by the group in `DOMAIN.md`.\n\n### Modified Capabilities\n\n## Impact\n\n- New code in `app/` only, with one test file per requirement in `app/test/`.\n- Not touched: `graph/`, `DOMAIN.md`.\n")
    spec = "## ADDED Requirements\n"
    for (i = 1; i <= nr; i++) {
      spec = spec "\n### Requirement: " rtitle[i] "\n" rtext[i] "\n"
      for (s = 1; s <= nsc[i]; s++) spec = spec "\n#### Scenario: " stitle[i, s] "\n- **WHEN** " swhen[i, s] "\n- **THEN** " sthen[i, s] "\n"
    }
    write(ch_dir "/specs/" cap "/spec.md", spec)
    tasks = "## 1. " product "\n\n"
    for (i = 1; i <= nt; i++) tasks = tasks (i > 1 ? "\n" : "") "- [ ] 1." i " " ttitle[i] " (ticket " pad(i) ")"
    write(ch_dir "/tasks.md", tasks "\n")
    # Tickets are Poteto\047s brief (pstack, orchestrate.md): every field filled, because a
    # worker cannot ask a question. check-bases.sh refuses a ticket with an empty field.
    for (i = 1; i <= nt; i++) {
      accept = ""
      for (s = 1; s <= nsc[i]; s++) accept = accept (s > 1 ? "\n" : "") "- " stitle[i, s] ": when " swhen[i, s] ", then " sthen[i, s] "."
      if (i == 1) before = "none, it is the first ticket."
      else {
        before = "the code of ticket" (i > 2 ? "s" : "") " "
        for (j = 1; j < i; j++) before = before (j > 1 ? " and " : "") pad(j)
        before = before " in `app/`; read it first."
      }
      t = ttest[i]
      write(h1 "/tickets/" pad(i) "-" tname[i] ".md", "# " pad(i) " \302\267 " ttitle[i] "\n\n## GOAL\n\n" fill(rtext[i]) "\n\n## SCOPE\n\nMay write: the code in `app/`, and the new test `app/test/" t ".test.html`.\nMay not write: `graph/`, `openspec/`, `tickets/`, `DOMAIN.md`.\n\n## CONTEXT\n\nThe requirement \"" ttitle[i] "\" and its scenarios in\n`openspec/changes/" change "/specs/" cap "/spec.md`. The client and the group\047s decisions\nare in `DOMAIN.md`. Proof it is missing: `ls app/test/` does not list `" t ".test.html`.\nDepends on: " before "\n\n## ACCEPTANCE\n\n" accept "\n\n## VERIFY\n\n`cd app && sh check.sh test`, then `sh check.sh typecheck` and `sh check.sh lint`. The\nnew test `app/test/" t ".test.html` checks every line of ACCEPTANCE; it fails before\nthe change and passes after it, with every other test.\n\n## FORBIDDEN\n\nThe other requirements of the change. New dependencies. Weakening or deleting a test.\n\n## REPORT\n\ndone or blocked, the files you changed, the names of the tests that ran, and the\n`sh check.sh test` output.\n")
    }
    write(h1 "/tickets/backlog-ready.md", "Signed off by the group: \"the backlog is ready\". Prepared base.\n")
    domains++
  }
  $1 == "domain" { slug = $2; nf = 0; nd = 0; nr = 0; nt = 0; next }
  $1 == "product" { product = $2 }
  $1 == "change" { change = $2 }
  $1 == "cap" { cap = $2 }
  $1 == "brief" { brief = $2 }
  $1 == "story" { story = $2 }
  $1 == "goal" { goal = $2 }
  $1 == "fact" { fact[++nf] = $2 }
  $1 == "decision" { nd++; dtitle[nd] = $2; dtext[nd] = $3; dchoice[nd] = $4; dknown[nd] = $5 }
  $1 == "req" { nr++; rtitle[nr] = $2; rtext[nr] = $3; nsc[nr] = 0 }
  $1 == "scenario" { s = ++nsc[nr]; stitle[nr, s] = $2; swhen[nr, s] = $3; sthen[nr, s] = $4 }
  $1 == "ticket" { nt++; tname[nt] = $2; ttitle[nt] = $3; ttest[nt] = $4 }
  $1 == "end" { generate() }
  END { print "ok", domains }
' <<'DOMAINS'
domain	checkout
product	Shop checkout
change	checkout-basket-and-returns
cap	checkout
brief	We run three small clothing shops and our tills are old. We want a checkout page on a tablet at the counter: the cashier adds products to a basket, sees the total and takes payment. Some products carry a discount sticker. Customers often bring back part of what they bought, and today that is a mess of paper notes.
story	Claire and Julien Morel own Fil, three small clothing shops in Lyon with six cashiers. Their tills are twelve years old and the vendor stopped supporting them last spring. In the Christmas sales one till died, and the shop in the Croix-Rousse wrote every sale on paper for two days. A normal Saturday afternoon: eight people in the queue, a shirt with a 30 % sticker that the cashier works out on a calculator, and a customer who brings back one of the two shirts she bought last week. The cashier writes the refund on a paper note. At closing time the notes and the drawer do not match, and Claire spends Sunday morning finding out why.
fact	Last month: 41 returns across the three shops, and 6 of them were refunded with the wrong amount.
fact	78 % of sales are paid by card. On Saturdays, at the shop next to the market, almost a third are cash.
fact	Prices on the shelf include VAT: in France a shop must show the customer the final price.
fact	Élodie, their accountant, files VAT every quarter and needs the VAT total of every sale.
fact	A discount sticker comes off the price before VAT, never after. Élodie checks it in every quarter's books.
fact	1 return in 5 comes without a receipt. Last year two of those were for clothes bought in another shop.
goal	A checkout on a tablet at every counter before the January sales. Done, for Claire, means a cashier closes a basket with a sticker and a partial return in under a minute, and the drawer matches the screen at closing time.
decision	Payment methods	Card only, or card and cash? Cash means counting a drawer at closing time; card only is simpler, but some customers only carry cash.	Card and cash.	Card is 78 % of sales, but the market shop takes almost a third in cash on Saturdays.
decision	VAT on screen	Prices with VAT included, or VAT as a separate line? Included is what customers see on the shelf; separate is what the accountant wants.	Prices include VAT; the receipt shows the VAT total at the end.	The law asks for the final price on the shelf; Élodie needs the VAT total of each sale.
decision	Returns without the receipt	Allowed or not? Allowing it is friendlier; refusing it avoids refunds for things that were never bought here.	Only with the receipt.	1 return in 5 has no receipt, and two of those last year were for clothes bought elsewhere.
req	Basket total	The checkout SHALL keep a basket of lines (product, unit price with VAT, quantity, optional discount in percent) and show its total.
scenario	Two lines	the basket has 2 shirts at 20.00 and 1 belt at 15.00	the total is 55.00
req	Partial returns	With the receipt of a past sale, the cashier SHALL return some of its lines and the checkout SHALL show the amount to refund.
scenario	Return one line	a receipt has 2 shirts at 20.00 and the customer returns 1 shirt	the refund is 20.00
req	Payment and change	The checkout SHALL take payment by card or cash; for cash it SHALL show the change.
scenario	Cash with change	the total is 55.00 and the customer pays 60.00 in cash	the change shown is 5.00
ticket	basket-total	Basket total	basket
ticket	partial-returns	Partial returns	returns
ticket	payment-and-change	Payment and change	payment
end
domain	inventory
product	Stock across shops
change	shop-stock-and-reservations
cap	stock
brief	We have four shops in the same city. Each shop keeps its own stock in a spreadsheet. When a customer wants a size that the shop does not have, the staff phone the other shops one by one. We want one page where staff see the stock of every shop and can reserve units in another shop for a customer.
story	Hélène Garnier runs Sabot, four shoe and clothing shops in Nantes. Each shop keeps its stock in its own spreadsheet, updated at night if somebody remembers. A customer tries a jacket in the old town shop and asks for it in size M. There is none on the shelf, so the assistant starts phoning the other three shops. The first one does not pick up, the second one has it but is busy, and by the time the third one calls back the customer has gone. When a shop does put a unit aside for someone, it is a sticky note on a box in the back room.
fact	Each shop makes about 9 of those calls a day, 4 minutes each. Last month 23 sales were lost waiting for an answer.
fact	7 in 10 of the questions are about a size or a colour, not about the product.
fact	Of the boxes put aside with a sticky note, 3 in 10 are never collected and stay out of stock for weeks.
fact	8 in 10 customers who reserve come within two days.
fact	Stock can never go below zero: a shop cannot reserve or sell a unit it does not have. Hélène's auditor counts it twice a year.
fact	Shop managers are on the shop floor two days a week; the rest of the time they are at the office.
goal	One page, open in all four shops, before the spring collection arrives in March. Done, for Hélène, means that a customer asking for a size in another shop leaves with a reservation instead of walking out.
decision	Unit of stock	Count single products, or each product per size and colour? Per size is what customers ask for; single products is much simpler to keep.	Per product, size and colour.	7 in 10 questions are about a size or a colour.
decision	How long a reservation lasts	Until the end of the day, or 48 hours? Short keeps stock free; long gives the customer time to come.	48 hours.	8 in 10 customers come within two days; 3 in 10 sticky-note boxes are never collected.
decision	Who can reserve	Any staff member, or only the shop manager? Anyone is faster; only the manager avoids reservations nobody follows up.	Any staff member.	Managers are on the floor only two days a week.
req	Stock per shop	The page SHALL show, for a product, size and colour, how many units each shop has.
scenario	Two shops	shop A has 3 units and shop B has 0 units of a blue shirt in size M	the page shows A: 3 and B: 0
req	Reserve in another shop	A staff member SHALL reserve units of a product in another shop for a customer; the reserved units SHALL stop counting as available.
scenario	Reserve one	shop A has 3 units and staff reserve 1 for a customer	shop A shows 2 available and 1 reserved
req	Reservations expire	A reservation SHALL expire after 48 hours and its units SHALL count as available again.
scenario	After two days	a reservation of 1 unit was made 49 hours ago	the unit counts as available again
ticket	stock-per-shop	Stock per shop	stock
ticket	reserve-in-another-shop	Reserve in another shop	reserve
ticket	reservations-expire	Reservations expire	expire
end
domain	loyalty
product	Loyalty points
change	loyalty-points
cap	loyalty
brief	We want our regular customers to come back. Every purchase earns points, and points can be spent on a later purchase. Today we stamp paper cards and people lose them or forget them at home.
story	Nuria Campos runs Verde, two organic food shops in Seville. Her regulars come two or three times a week, and she wants to keep them now that a supermarket chain has opened an organic aisle two streets away. Today every customer gets a paper card with ten boxes to stamp. People lose the cards, leave them at home, or show up with three half-full ones. At seven in the evening, with a queue to the door, the cashier is counting stamps by hand and stamping twice to be kind.
fact	Verde has handed out about 1,800 paper cards. 4 regulars in 10 forget the card on any given day.
fact	The average basket is 23 euros. The busiest hour is seven to eight in the evening.
fact	Almost every regular has a mobile phone. Many of the older ones never open an app or a QR code.
fact	Points expire 12 months after they are earned. Nuria's accountant needs it: unspent points count as a debt to the customer.
fact	Nuria can give away 5 % of a sale, not more, or the shop stops making money on it.
goal	Points live in both shops before the summer, when the regulars start to go to the beach. Done, for Nuria, means a regular earns and spends points at the till without a card and without slowing the queue.
decision	How points are earned	1 point per euro, or 1 point per 10 euros but each point worth more? Per euro feels generous and is easy to explain; per 10 euros keeps numbers small.	1 point per euro spent.	The average basket is 23 euros: 23 points, or 2.
decision	How the customer is identified	Phone number, or a QR code on their phone? A phone number works for everyone; a QR code is faster and keeps the number private.	Phone number.	Almost everyone has a phone; many of the older regulars never open a QR code.
decision	Minimum to spend points	Any amount, or blocks of 100 points? Any amount is flexible; blocks are easier at the till.	Blocks of 100 points; 100 points take 5.00 off.	The queue peaks at seven in the evening, and Nuria can give away 5 % of a sale at most.
req	Earn points	Each purchase SHALL add 1 point per whole euro spent to the customer, identified by phone number.
scenario	A purchase	a customer with 0 points buys for 42.80	the customer has 42 points
req	Spend points	At the till, a customer with at least 100 points SHALL spend them in blocks of 100, each block taking 5.00 off the total.
scenario	One block	a customer has 130 points and the total is 30.00	after spending one block the total is 25.00 and 30 points are left
req	Customer history	The page SHALL show a customer's purchases and point movements, newest first.
scenario	Two movements	a customer earned 42 points and later spent 100	the history shows the spend first, then the earn
ticket	earn-points	Earn points	earn
ticket	spend-points	Spend points	spend
ticket	customer-history	Customer history	history
end
domain	promotions
product	Shop promotions
change	weekly-promotions
cap	promotions
brief	Our marketing team runs promotions every week: second unit at half price, 20 % off jackets, buy 3 pay 2. Today the cashier has to remember them and apply them by hand, and gets them wrong. We want promotions defined once and applied at the till.
story	Jorge Sanz leads marketing at Brisa, nine sportswear shops around Madrid. Every Monday his team of two decides the week's promotions and emails a PDF to every shop. The cashiers print it, pin it next to the till, and apply each promotion by hand. On a busy Saturday a cashier forgets that the second pair of socks is half price, the customer notices at home, and on Monday there is a complaint and a refund. Last week a jacket got 20 % off twice, because it was in two promotions at once.
fact	An audit of one month found 1 promoted basket in 8 charged wrong: about 3,100 euros, some given away and some overcharged.
fact	Promotions change every Monday. IT is one person, two days a week.
fact	Customers who see what they saved come back more often, says Jorge's last survey.
fact	Promotions never stack: a product gets one promotion, the best one for the customer. The jacket at 20 % twice broke that rule.
fact	The receipt printer prints on narrow paper; every extra line makes the queue a little slower.
goal	Promotions defined once and applied at every till before Black Friday, the busiest week of the year. Done, for Jorge, means no cashier has to remember a promotion, and the Monday complaints stop.
decision	Who creates promotions	Marketing on a page, or a file that IT updates? A page gives marketing control; a file is quicker to build and harder to break.	Marketing on a page.	Promotions change every Monday, and IT is one person two days a week.
decision	When a promotion applies	Automatically at the till, or the cashier picks it? Automatic never forgets; picking lets the cashier explain it to the customer.	Automatically.	1 promoted basket in 8 was charged wrong when the cashier applied it by hand.
decision	Savings on the receipt	Show what the customer saved, or not? Showing it sells the promotion; hiding it keeps the receipt short.	Show the savings.	Customers who see what they saved come back more often; the paper is narrow.
req	Active promotions	The page SHALL list the promotions active on a given date, with their start and end dates.
scenario	One active, one past	one promotion runs this week and another ended last week	only this week's promotion is listed
req	Second unit at half price	When a basket has two units of a product in a 'second unit at 50 %' promotion, the second unit SHALL cost half.
scenario	Two shirts	a shirt costs 20.00, is in the promotion, and the basket has 2	the basket total is 30.00
req	Savings on the receipt	The receipt SHALL show the total saved by promotions.
scenario	One promotion applied	the second shirt was half price	the receipt shows 'You saved 10.00'
ticket	active-promotions	Active promotions	promotions
ticket	second-unit-half-price	Second unit at half price	second-unit
ticket	savings-on-receipt	Savings on the receipt	savings
end
DOMAINS
