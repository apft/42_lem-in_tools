#!/bin/sh

NB_TESTS="$1"
shift
TYPE="$1"
shift

MAP=".map"
MAP_BFR=".map_old"

function initialize_array_comp()
{
	for i in {0..20}
	do
		COMP[$i]=0
	done
}

function generate_new_map()
{
	while true
	do
		./generator "--$TYPE" > $MAP
		diff_map=`diff $MAP ${MAP_BFR} | head -n 1`
		[ "${diff_map}" ] && break;
	done
}

function print_header()
{
	printf "        exp  "
	for bin in $@
	do
		printf "%*s  " 19 $bin
	done
	printf "\n"
}

function	run()
{
	MAX_DIFF_LINES=-999999
	MIN_DIFF_LINES=999999
	local sum_diff_lines=0
	print_header $@

	local i=1;
	while [ $i -le $NB_TESTS ];
	do
		generate_new_map
		max=`tail -n 1 $MAP | cut -d ':' -f 2 | bc`
		printf "%4d : %4d  " $i $max
		j=0
		for bin in $@
		do
			usr=`$bin < $MAP | grep "^L" | wc -l | bc`
			time=`{ time $bin < $MAP ; } 2>&1 | grep real | cut -f2`
			if [ ${#bin} -lt 19 ]; then
				printf "%4d (%+3d) %s  "  $usr $((usr-max)) $time
			else
				printf "%*s%4d (%+3d) %s  " $((${#bin} - 19)) "" $usr $((usr-max)) $time
			fi
			local diff=$((usr-max))
			[ ${#@} -eq 1 ] && [ "$diff" -lt "$MIN_DIFF_LINES" ] && MIN_DIFF_LINES="$diff"
			[ ${#@} -eq 1 ] && [ "$diff" -gt "$MAX_DIFF_LINES" ] && MAX_DIFF_LINES="$diff"
			[ ${#@} -eq 1 ] && sum_diff_lines=$((sum_diff_lines + diff))
			((j++))
		done
		[ ${#@} -eq 1 ] && let "COMP[$((10 + usr - max))]++"
		mv $MAP ${MAP_BFR}
		printf "\n"
		((i++))
	done
	[ ${#@} -eq 1 ] && AVERAGE_DIFF_LINES=`scale=2; echo "$sum_diff_lines/$NB_TESTS" | bc -l`
}

function	print_graph()
{
	big=`echo "${COMP[@]}" | tr ' ' '\n' | sort -gr | head -n 1`
	for i in `seq $big`
	do
		for j in {0..20}
		do
			rank=`echo "$big - $i + 1" | bc`
			printf " "
			[ "${COMP[$j]}" -ge $rank ] &&  printf "   ." || printf "    "
		done
		printf " $d\n" $((big - i))
	done
}

function	print_summary()
{
	printf "\n"
	for i in {-10..10}
	do
		printf " %+4d" $i
	done
	printf "\n"
	for i in {0..20}
	do
		printf " %4d" ${COMP[$i]}
	done
	printf "\n"

	print_graph

	printf "\nResults\n"
	printf "  ⤷ Average: %.2f\n" "$AVERAGE_DIFF_LINES"
	printf "  ⤷ Min: %d\n" "$MIN_DIFF_LINES"
	printf "  ⤷ Max: %d\n" "$MAX_DIFF_LINES"
}

touch $MAP ${MAP_BFR}

initialize_array_comp
run $@
[ ${#@} -eq 1 ] && print_summary

rm ${MAP_BFR}
