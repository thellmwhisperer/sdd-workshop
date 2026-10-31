# Standing orders

One rule per line. The graph pastes this file, as it is, into the brief of every worker and
reviewer. When the same correction comes up twice, for example the reviewer blocks two
runs for the same reason, the chief adds a line here instead of saying it again.

1. Change only the files your SCOPE allows.
2. Never weaken, skip or delete a test to get green.
3. Never guess a business rule. If the spec does not say it, report blocked and say what is missing.
4. Write code, tests and reports in English.
5. The app runs in a browser and nowhere else: HTML, CSS and JavaScript exactly as a browser loads them. No Node, no npm, no modules (`import`, `export`, `require`), no build step, no dependency. A test is a page, `app/test/<name>.test.html`, that `app/check.sh test` runs in the browser; it prints one `ok` or `FAIL` line per check. `app/check.sh lint` is red otherwise.
