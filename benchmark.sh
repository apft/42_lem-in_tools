FILE="$1"
[ "$2" ] && EXEC="$2" || EXEC="./lem-in"

TMP_OUT=tmp_out

$EXEC < $FILE > $TMP_OUT
PATHS=`cat $TMP_OUT | grep ^L | head -n 1`
NB_PATHS=`echo "$PATHS" | wc -w | bc`

echo "Paths:"
echo "$PATHS"
echo "\nNb of paths: $NB_PATHS"
i=1
while [ $i -le $NB_PATHS ];
do
	path_length=`cat $TMP_OUT | grep "L$i-" | wc -l | bc`
	path_name=`echo $PATHS | tr ' ' '\n' | grep "L$i-" | cut -d '-' -f2`
	printf "%d: (%d, %s)" $i $path_length $path_name
	if [ $i -lt $NB_PATHS ];then
		printf " | "
	fi
	((i++));
done
printf "\n"

rm -f $TMP_OUT
