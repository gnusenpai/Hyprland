#!/bin/sh
for arg in "$@"; do
case $arg in
--reshade )
shift
RESHADE=1
;;
esac
done

CAL=$1
TEMPLATE=$2
DATA=$(
    sed '/END_DATA$/Q' "${CAL}" |
        tac |
        sed '/BEGIN_DATA$/Q' |
        tac |
        cut -d' ' -f2- |
        sed -e 's/ /,/g' -e 's/^/    vec3(/' -e 's/$/),/'
)

SIZE=$(echo "${DATA}" | wc -l)
DATA=$(echo "${DATA}" | tr '\n' '@' | sed 's/,@$//')

sed -e "s/^.*1DLUT_REPLACE_LIST/${DATA}/" -e "s/1DLUT_REPLACE_NUMBER/${SIZE}/" "${TEMPLATE}" |
    tr '@' '\n' | if [ "$RESHADE" = "1" ]; then sed -e 's/vec3/float3/' | tr -d "\r"; else cat; fi

