#!/bin/sh
compile () {
    sed -E -e '
    s:\s*$::
    s:^//:#:
    s:^([a-z0-9._]+),\s([a-z0-9._]+)$:s/(pattern|tileset) = "\1"/\\1 = "\2"/:
    s:^([a-z0-9._]+)$:/"\1"/d:
    '   
}
SCRIPT="
:loop
/}/b done
N
s/\n//
b loop
/^$/d
:done
`compile < diff_delete`
`compile < diff_replace`
s/,/,\n/g
s/\{/{\n/g
s/\}/}\n/g
/^$/D
"
find "$@" -name '*.dat' -exec echo {} \; -exec sed -i -E "$SCRIPT" {} \;
