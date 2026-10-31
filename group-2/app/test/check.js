// The test helper of the app. A test page loads it with <script src="check.js"></script>
// and calls check() once per line of ACCEPTANCE. Every check writes one line into
// <pre id="result">, `ok <name>` or `FAIL <name>: <why>`, and `sh app/check.sh test` reads
// those lines from the page after the browser ran it. Only check and checkThrows are
// global; the rest stays inside, so it never clashes with a name of the app.
(function () {
  // result: the <pre id="result"> of the page; made at the end of the body when there is none.
  function result() {
    var pre = document.getElementById("result");
    if (!pre) {
      pre = document.createElement("pre");
      pre.id = "result";
      (document.body || document.documentElement).appendChild(pre);
    }
    return pre;
  }

  // say(line): adds one line to the result.
  function say(line) {
    var pre = result();
    pre.textContent += (pre.textContent === "" ? "" : "\n") + line;
  }

  // show(value): a value as JSON, the way a FAIL line shows it.
  function show(value) {
    return String(JSON.stringify(value));
  }

  // check(name, got, want): ok when got and want are the same as JSON.
  window.check = function (name, got, want) {
    if (show(got) === show(want)) {
      say("ok " + name);
    } else {
      say("FAIL " + name + ": got " + show(got) + ", want " + show(want));
    }
  };

  // checkThrows(name, fn, message): ok when fn() throws an Error whose message contains
  // message.
  window.checkThrows = function (name, fn, message) {
    try {
      fn();
    } catch (e) {
      if (e instanceof Error && e.message.indexOf(message) >= 0) {
        say("ok " + name);
      } else {
        say("FAIL " + name + ": threw " + show(e instanceof Error ? e.message : e) +
          ", want an error with " + show(message));
      }
      return;
    }
    say("FAIL " + name + ": threw nothing, want an error with " + show(message));
  };

  // An error outside a check, a syntax error too, is a failure with its reason.
  window.onerror = function (message) {
    say("FAIL " + document.title + ": " + message);
  };
})();
