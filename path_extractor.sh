#!/bin/sh

PATHS="map/paths/"

for i in "$@"
do
	echo $i
	./lem-in < $i > out
	[ $? -ne 0 ] && echo " > KO" && continue
	file=`basename $i`
	paths_line=`grep -n -i "paths" out | cut -d ':' -f 1`
	nb_line=`wc -l out | rev | cut -d ' ' -f 2 | rev`
	echo "${paths_line} : ${nb_line}"
	tail -n $((nb_line - paths_line + 1)) out > ${PATHS}$file
done
