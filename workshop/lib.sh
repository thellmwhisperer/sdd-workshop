#!/bin/sh
# Shared functions for the workshop scripts. Sourced, not run: . "$(dirname "$0")/lib.sh"
#
# A group's starting point for hour N is built in layers:
#   workshop/template/                    the empty project, the same for everyone
#   workshop/domains/<domain>/DOMAIN.md   the client's brief, with open decisions
#   for each hour h before N:
#     workshop/solutions/hour-h/          what that hour builds, the same for everyone
#     workshop/domains/<domain>/hour-h/   what that hour produces for this domain
#   for each hour h up to N:
#     workshop/inputs/hour-h/             what hour h starts with: its change, its
#                                         contract, its ticket and its stub. Also copied by
#                                         start-hour.sh when a group starts hour h with
#                                         its own work, without overwriting anything.

workshop=$(cd "$(dirname "$0")" && pwd)

# domain_of <group-dir>: the domain assigned to the group in groups.txt
domain_of() {
  awk -v g="$(basename "$1")" '$1 == g { print $2 }' "$workshop/groups.txt"
}

# add_inputs <group-dir> <hour>: copies what that hour starts with into the group folder,
# file by file, never overwriting a file the group already has.
add_inputs() {
  ai_src="$workshop/inputs/hour-$2"
  [ -d "$ai_src" ] || return 0
  (cd "$ai_src" && find . -type f) | while read -r f; do
    [ -e "$1/$f" ] && continue
    mkdir -p "$(dirname "$1/$f")"
    cp "$ai_src/$f" "$1/$f"
  done
}

# build_base <group-dir> <domain> <hour>: fills an empty group folder with the starting
# point of that hour. Fails when the domain does not exist.
build_base() {
  bb_dir=$1
  bb_src="$workshop/domains/$2"
  if [ ! -f "$bb_src/DOMAIN.md" ]; then
    printf 'unknown domain: %s\n' "$2" >&2
    return 1
  fi
  mkdir -p "$bb_dir"
  cp -R "$workshop/template/." "$bb_dir/"
  cp "$bb_src/DOMAIN.md" "$bb_dir/DOMAIN.md"
  bb_h=1
  while [ "$bb_h" -lt "$3" ]; do
    for bb_layer in "$workshop/inputs/hour-$bb_h" "$workshop/solutions/hour-$bb_h" "$bb_src/hour-$bb_h"; do
      if [ -d "$bb_layer" ]; then cp -R "$bb_layer/." "$bb_dir/"; fi
    done
    bb_h=$((bb_h + 1))
  done
  add_inputs "$bb_dir" "$3"
  # The product's name, in the app and the living spec: & / and \ escaped for sed.
  bb_product=$(sed -n 's/^# Product: //p' "$bb_dir/DOMAIN.md" | head -n 1 | sed 's/[&/\]/\\&/g')
  for bb_top in "$bb_dir/app" "$bb_dir/openspec/specs"; do
    [ -d "$bb_top" ] || continue
    grep -rl __PRODUCT__ "$bb_top" | while read -r f; do
      sed "s/__PRODUCT__/$bb_product/g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    done
  done
}
