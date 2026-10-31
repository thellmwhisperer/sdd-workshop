#!/bin/sh
# The tests of one group's app on GitHub, before it is published: sh .github/pages/test.sh group-<N>
# Run by .github/workflows/group-<N>.yml. The same checks the group runs on its laptop,
# sh group-<N>/app/check.sh test and lint, with the runner's Chrome. On the runner Chrome
# cannot use its sandbox, so check.sh gets, through BROWSER, a Chrome that starts without it.
set -eu
group=${1:?usage: sh .github/pages/test.sh group-<N>}
wrapper=${RUNNER_TEMP:-${TMPDIR:-.}}/chrome-no-sandbox
chrome=$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || true)
if [ -z "$chrome" ]; then
  printf 'no Chrome on this machine\n' >&2
  exit 1
fi
printf '#!/bin/sh\nexec "%s" --no-sandbox "$@"\n' "$chrome" > "$wrapper"
chmod +x "$wrapper"
BROWSER=$wrapper sh "$group/app/check.sh" test
sh "$group/app/check.sh" lint
