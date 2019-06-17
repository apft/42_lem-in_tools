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

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
NC='\033[0m'

function initialize_arrays()
{
	local i=1
	for bin in $@
	do
		COMP_DIFF[$i]=0
		COMP_NB_LINES[$i]=0
		COMP_TIME[$i]=0
		COMP_WIN_DIFF[$i]=0
		COMP_BIN[$i]="$bin"
		((i++))
	done

}

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

function get_value_winner_diff()
{
	local min="${COMP_DIFF[1]}"

	for i in `seq ${#@}`
	do
		if [ "${COMP_DIFF[$i]}" -lt "$min" ];then
			min="${COMP_DIFF[$i]}"
		fi
	done
	printf "%d" $min
}

function get_value_winner_time()
{
	local min="${COMP_TIME[1]}"

	for i in `seq ${#@}`
	do
		local compare=`echo "${COMP_TIME[$i]} < $min" | bc -l`
		if  [ $compare -eq 1 ];then
			min="${COMP_TIME[$i]}"
		fi
	done
	printf "%.3f" $min
}

function print_result_line()
{
	local value_winner_diff=`get_value_winner_diff $@`
	local value_winner_time=`get_value_winner_time $@`

	for i in `seq ${#@}`
	do
		if [ "${COMP_DIFF[$i]}" -gt 0 ]; then
			marker_diff=${RED}
		elif [ "${COMP_DIFF[$i]}" -eq "$value_winner_diff" ]; then
			marker_diff=${GREEN}
			((COMP_WIN[$i]++))
		else
			marker_diff=${NC}
		fi
		local compare_time=`echo "${COMP_TIME[$i]} == $value_winner_time" | bc -l`
		if [ $compare_time -eq 1 ]; then
			marker_time=${GREEN}
		else
			marker_time=${NC}
		fi
		if [ ${#COMP_BIN[$i]} -lt 19 ]; then
			printf "%4d ${marker_diff}(%+3d)${NC} ${marker_time}0m%.3fs${NC}  "  ${COMP_NB_LINES[$i]} ${COMP_DIFF[$i]} ${COMP_TIME[$i]}
		else
			printf "%*s%4d ${marker_diff}(%+3d)${NC} ${marker_time}0m%.3fs${NC}  " $((${#COMP_BIN[$i]} - 19)) "" ${COMP_NB_LINES[$i]} ${COMP_DIFF[$i]} ${COMP_TIME[$i]}
		fi
		printf "${NC}"
	done
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
		j=1
		COMP_NB_LINES[0]=$max
		for bin in $@
		do
			{ time $bin < $MAP; } > $tmp_out 2>&1
			usr=`grep "^L" $tmp_out | wc -l | bc`
			time=`grep real $tmp_out | cut -f2`
			time_nb=`echo $time | cut -c3-7 | bc -l`
			[ ${#@} -eq 1 ] && sum_time=`scale=3; echo "$sum_time + $time_nb" | bc -l`
			local diff=$((usr-max))
			COMP_DIFF[$j]="$diff"
			COMP_NB_LINES[$j]="$usr"
			COMP_TIME[$j]="$time_nb"
			[ ${#@} -eq 1 ] && [ "$diff" -lt "$MIN_DIFF_LINES" ] && MIN_DIFF_LINES="$diff"
			[ ${#@} -eq 1 ] && [ "$diff" -gt "$MAX_DIFF_LINES" ] && MAX_DIFF_LINES="$diff"
			[ ${#@} -eq 1 ] && sum_diff_lines=$((sum_diff_lines + diff))
			((j++))
		done
		[ ${#@} -eq 1 ] && let "COMP[$((10 + usr - max))]++"
		print_result_line $@
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

function	get_value_winner()
{
	local max="${COMP_WIN[1]}"

	for i in `seq ${#@}`
	do
		if [ ${COMP_WIN[$i]} -gt $max ]; then
			max="${COMP_WIN[$i]}"
		fi
	done
	printf "%d" $max
}

function	print_winners()
{
	local	value_winner=`get_value_winner $@`

	printf "WINNER(S):"
	for i in `seq ${#@}`
	do
		if [ ${COMP_WIN[$i]} -eq $value_winner ];then
			printf " %s" "${COMP_BIN[$i]}"
		fi
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
initialize_arrays $@
run $@
[ ${#@} -eq 1 ] && print_summary || print_winners $@

rm ${MAP_BFR}
