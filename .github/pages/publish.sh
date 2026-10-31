#!/bin/sh
# Publishes one group's app on the workshop's site: sh .github/pages/publish.sh group-<N>
# Run by .github/workflows/group-<N>.yml on GitHub, after the app's tests are green, each
# time a pull request that touches group-<N>/app/ is merged into main.
# The site is the branch gh-pages, which GitHub Pages serves: one folder per group,
#   https://<owner>.github.io/<repo>/group-<N>/
# Each group replaces only its own folder, so a group never touches another's site, and a
# group whose tests are red keeps the last site that was green. The page at the root lists
# the groups that have published. When two groups publish at once, the second push is
# refused; it starts again from the site as the first one left it, up to five times.
set -eu
group=${1:?usage: sh .github/pages/publish.sh group-<N>}
if [ ! -d "$group/app" ]; then
  printf 'no %s/app in this checkout\n' "$group" >&2
  exit 1
fi
product=$(sed -n 's/^# Product: //p' "$group/DOMAIN.md" 2> /dev/null | head -n 1)
site=${RUNNER_TEMP:-.}/site
git config user.name 'github-actions[bot]'
git config user.email '41898282+github-actions[bot]@users.noreply.github.com'

# publish: one attempt. Exit 0 published or nothing to publish, 1 the push was refused.
publish() {
  # The site as it is now, or a new empty branch the first time.
  if git ls-remote --exit-code --heads origin gh-pages > /dev/null 2>&1; then
    git fetch -q origin gh-pages
    git worktree add -q --detach "$site" FETCH_HEAD
  else
    git worktree add -q --detach "$site"
    git -C "$site" checkout -q --orphan gh-pages
    git -C "$site" rm -rqf .
  fi

  # This group's folder, replaced by its app as merged; the browser's test profile is not part of it.
  rm -rf "${site:?}/$group"
  mkdir -p "$site/$group"
  cp -R "$group/app/." "$site/$group/"
  rm -rf "$site/$group/.browser"
  if [ -n "$product" ]; then printf '%s\n' "$product" > "$site/$group/.product"; fi
  : > "$site/.nojekyll"

  # The root page: a link per group that has published.
  {
    printf '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
    printf '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
    printf '<title>From brief to pull request: the groups</title>\n</head>\n<body>\n'
    printf '<h1>The groups</h1>\n<ul>\n'
    for d in "$site"/group-*/; do
      [ -d "$d" ] || continue
      g=$(basename "$d")
      p=$(cat "$d/.product" 2> /dev/null || true)
      printf '<li><a href="%s/">%s</a>%s</li>\n' "$g" "$g" "${p:+: $p}"
    done
    printf '</ul>\n</body>\n</html>\n'
  } > "$site/index.html"

  git -C "$site" add -A
  status=0
  if git -C "$site" diff --cached --quiet; then
    printf '%s: the site already has this app, nothing to publish\n' "$group"
  else
    git -C "$site" commit -qm "$group: app of ${GITHUB_SHA:-$(git rev-parse --short HEAD)}"
    if git -C "$site" push -q origin HEAD:gh-pages; then
      printf '%s published\n' "$group"
    else
      status=1
    fi
  fi
  git worktree remove --force "$site"
  return $status
}

for try in 1 2 3 4 5; do
  if publish; then exit 0; fi
  printf '%s: another group published at the same time, again (try %s of 5)\n' "$group" "$try"
  sleep "$try"
done
printf '%s: the site refused five times; run this workflow again\n' "$group" >&2
exit 1
