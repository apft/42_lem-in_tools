#!/bin/sh

# recuperer le nombre de chemin : 1ere ligne
# creer le tableau de longeur des chemind
# pour le reste des fourmis, checker que la longeur de son chemin est coherente

EXEC="$1"
FILE="$2"

OUTPUT=".out_checker"
$EXEC < $FILE > $OUTPUT

NB_ANTS=`head -n 1 $FILE`
NB_PATH=`grep "^L" $OUTPUT | head -n 1 | grep -o "L" | wc -l | bc`

echo "ants: ${NB_ANTS}"
echo "path: ${NB_PATH}"

function length()
{
	local	index="$1"
	grep "L${index}-" $OUTPUT | wc -l | bc
}

for i in `seq ${NB_PATH}`
do
	PATH_LENGTH[$i]=`length $i`
done

echo "path length: ${PATH_LENGTH[@]}"

for i in `seq ${NB_ANTS}`
do
	length=`length $i`
	echo "${PATH_LENGTH[@]}" | grep "$length" > /dev/null
	if [ $? -ne 0 ]; then
		echo "error: ant $i goes through a path length of $length"
		exit
	fi
done

[ -f "$OUTPUT" ] && rm "$OUTPUT"
