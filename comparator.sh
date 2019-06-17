#!/bin/sh

function print_usage()
{
	echo "usage:"
	echo "\t$0 nb type exe [exe ...]\n"
	echo "example:"
	echo "\t$0 25 big-superposition ./lem-in"
	echo "\t\t> run 25 times 'lem-in' programm with random big-superposition map"
	echo "\t$0 15 big /path/project1/lem-in /path/project2/lem-in"
	echo "\t\t> run 15 times each programm with random big map"
	echo "options:"
	echo "\t- nb\tnumber of tests to run"
	echo "\t- type\tant farm size based on 'generator' options (run './generator --help' for more information)"
	echo "\t- exe\tpath to each executable file to compare"
}

[ $# -lt 3 ] && print_usage && exit 1;

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
	local sum_time=0.0
	local tmp_out=out.tmp
	print_header $@

	for i in `seq $NB_TESTS`
	do
		generate_new_map
		max=`tail -n 1 $MAP | cut -d ':' -f 2 | bc`
		printf "%4d : %4d  " $i $max
		j=0
		for bin in $@
		do
			{ time $bin < $MAP; } > $tmp_out 2>&1
			usr=`grep "^L" $tmp_out | wc -l | bc`
			time=`grep real $tmp_out | cut -f2`
			time_nb=`echo $time | cut -c3-7 | bc -l`
			[ ${#@} -eq 1 ] && sum_time=`scale=3; echo "$sum_time + $time_nb" | bc -l`
			local diff=$((usr-max))
			if [ ${#bin} -lt 19 ]; then
				printf "%4d (%+3d) %s  "  $usr $diff $time
			else
				printf "%*s%4d (%+3d) %s  " $((${#bin} - 19)) "" $usr $diff $time
			fi
			[ ${#@} -eq 1 ] && [ "$diff" -lt "$MIN_DIFF_LINES" ] && MIN_DIFF_LINES="$diff"
			[ ${#@} -eq 1 ] && [ "$diff" -gt "$MAX_DIFF_LINES" ] && MAX_DIFF_LINES="$diff"
			[ ${#@} -eq 1 ] && sum_diff_lines=$((sum_diff_lines + diff))
			((j++))
		done
		[ ${#@} -eq 1 ] && let "COMP[$((10 + usr - max))]++"
		mv $MAP ${MAP_BFR}
		printf "\n"
	done
	[ ${#@} -eq 1 ] && AVERAGE_DIFF_LINES=`scale=2; echo "$sum_diff_lines/$NB_TESTS" | bc -l`
	[ ${#@} -eq 1 ] && AVERAGE_TIME=`scale=3; echo "$sum_time/$NB_TESTS" | bc -l`
	rm -f $tmp_out
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

function	print_axis()
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
}

function	print_summary()
{
	print_graph
	print_axis

	printf "\nResults\n"
	printf "  ⤷ Time average: %.3fs\n" "$AVERAGE_TIME"
	printf "  ⤷ Average: %.2f\n" "$AVERAGE_DIFF_LINES"
	printf "  ⤷ Min: %d\n" "$MIN_DIFF_LINES"
	printf "  ⤷ Max: %d\n" "$MAX_DIFF_LINES"
}

touch $MAP ${MAP_BFR}

initialize_array_comp
run $@
[ ${#@} -eq 1 ] && print_summary

rm ${MAP_BFR}
