#!/bin/sh

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
UNDERLINE='\033[4m'
NC='\033[0m'
RESET='\033[0m'

OUTPUT_LENGTH=19

print_usage()
{
	echo "usage:"
	echo "\t$0 nb type exe [exe ...]\n"
	echo "example:"
	echo "\t$0 25 big-superposition ./lem-in"
	echo "\t\t> run 25 times 'lem-in' program with random big-superposition map"
	echo "\t$0 15 big /path/project1/lem-in /path/project2/lem-in"
	echo "\t\t> run 15 times each program with random big map"
	echo "options:"
	echo "    nb     number of tests to run"
	echo "    type   ant farm size based on 'generator' options {flow-one, flow-ten, flow-thousand, big, big-superposition}"
	echo "             (run './generator --help' for more information)"
	echo "    exe    path to each executable file to compare"
}

print_usage_and_exit()
{
	print_usage
	exit 1
}

print_usage_error_and_exit()
{
	printf "error: %s\n\n" "$1"
	print_usage_and_exit
}

initialize_arrays()
{
	local i=1
	for bin in $@
	do
		ERROR[$i]=0
		COMP_DIFF[$i]=0
		COMP_NB_LINES[$i]=0
		COMP_TIME[$i]=0
		COMP_WIN_DIFF[$i]=0
		COMP_BIN[$i]="$bin"
		((i++))
	done

}

initialize_array_comp()
{
	for i in {0..20}
	do
		COMP[$i]=0
	done
}

generate_new_map()
{
	while true
	do
		./generator "--$TYPE" > $MAP
		diff_map=`diff $MAP ${MAP_BFR} | head -n 1`
		[ "${diff_map}" ] && break;
	done
}

print_header()
{
	printf "%*s${UNDERLINE} %*s exp ${NC}" 7 "" $((2*${#@}))""
	for bin in $@
	do
		printf "${UNDERLINE}%*s  ${RESET}" $OUTPUT_LENGTH $bin
	done
	printf "\n"
}

timeout_fct()
{
	local timeout_limit=$1
	local bin=$2
	local tmp_out=$3
	local future_date=$((`date +%s` + $timeout_limit))

	{ time $bin < $MAP; } > $tmp_out 2>&1 &
	local pid=`echo $!`
	while ps -p $pid > /dev/null
	do
		local now=`date +%s`
		if [ $now -ge $future_date ]; then
			kill $pid
			wait $pid
			return 2
		fi
	done
	return 0
}

get_value_winner_diff()
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

get_value_winner_time()
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

print_result_line()
{
	[ ${#@} -gt 1 ] && local value_winner_diff=`get_value_winner_diff $@`
	[ ${#@} -gt 1 ] && local value_winner_time=`get_value_winner_time $@`

	for i in `seq ${#@}`
	do
		if [ ${ERROR[$i]} -ne 0 ]; then
			local width
			local msg="error"
			[ ${ERROR[$i]} -eq 2 ] && msg="timeout"
			[ ${#COMP_BIN[$i]} -lt $OUTPUT_LENGTH ] && width=$OUTPUT_LENGTH || width=${#COMP_BIN[$i]}
			printf "${RED}%*s${NC}  " $width "$msg"
			continue
		fi
		if [ "${COMP_DIFF[$i]}" -gt 0 ]; then
			marker_diff=${RED}
		elif [ ${#@} -gt 1 ] && [ "${COMP_DIFF[$i]}" -eq "$value_winner_diff" ]; then
			marker_diff=${GREEN}
			((COMP_WIN_DIFF[$i]++))
		else
			marker_diff=${NC}
		fi
		[ ${#@} -gt 1 ] && local compare_time=`echo "${COMP_TIME[$i]} == $value_winner_time" | bc -l`
		if [ ${#@} -gt 1 ] && [ $compare_time -eq 1 ]; then
			marker_time=${GREEN}
		else
			marker_time=${NC}
		fi
		if [ ${#COMP_BIN[$i]} -lt $OUTPUT_LENGTH ]; then
			printf "%4d ${marker_diff}(%+3d)${NC} ${marker_time}0m%.3fs${NC}  "  ${COMP_NB_LINES[$i]} ${COMP_DIFF[$i]} ${COMP_TIME[$i]}
		else
			printf "%*s%4d ${marker_diff}(%+3d)${NC} ${marker_time}0m%.3fs${NC}  " $((${#COMP_BIN[$i]} - $OUTPUT_LENGTH)) "" ${COMP_NB_LINES[$i]} ${COMP_DIFF[$i]} ${COMP_TIME[$i]}
		fi
		printf "${NC}"
	done
	printf "\n"
}

run()
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
		printf "%4d : " $i
		j=1
		COMP_NB_LINES[0]=$max
		for bin in $@
		do
			timeout_fct $TIMEOUT $bin $tmp_out > /dev/null 2>&1
			local status=$?
			if [ $status -eq 0 ]; then
				printf "${GREEN}✔ ${NC}"
			else
				ERROR[$j]=$status
				printf "${RED}✗ ${NC}"
				((++j))
				continue
			fi
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
			[ ${#@} -eq 1 ] && let "COMP[$((10 + usr - max))]++"
			((j++))
		done
		printf " %4d " $max
		print_result_line $@
		mv $MAP ${MAP_BFR}
	done
	[ ${#@} -eq 1 ] && AVERAGE_DIFF_LINES=`scale=2; echo "$sum_diff_lines/$NB_TESTS" | bc -l`
	[ ${#@} -eq 1 ] && AVERAGE_TIME=`scale=3; echo "$sum_time/$NB_TESTS" | bc -l`
	rm -f $tmp_out
}

print_graph()
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

print_axis()
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

get_value_winner()
{
	local max="${COMP_WIN_DIFF[1]}"
	for i in `seq ${#@}`
	do
		if [ "${COMP_WIN_DIFF[$i]}" -gt "$max" ]; then
			max="${COMP_WIN_DIFF[$i]}"
		fi
	done
	printf "%d" $max
}

print_winners()
{
	local	value_winner=`get_value_winner $@`
	local	is_tie=`is_this_a_tie $value_winner $@`

	printf "\n"
	if [ $is_tie -eq 1 ]; then
		printf "🏆  THIS IS A TIE! THE WINNERS ARE "
	else
		printf "🏆  THE WINNER IS"
	fi
	for i in `seq ${#@}`
	do
		if [ "${COMP_WIN_DIFF[$i]}" -eq "$value_winner" ];then
			printf " ${GREEN}%s${NC}" "${COMP_BIN[$i]}"
			if [ $is_tie -eq 0 ]; then
				break
			fi
		fi
	done
	printf " 🏆 \n"
}

is_this_a_tie()
{
	local	value_winner=$1
	local	nb_occur=0
	shift
	for i in `seq ${#@}`
	do
		if [ "${COMP_WIN_DIFF[$i]}" -eq "$value_winner" ];then
			((nb_occur++))
		fi
		if [ $nb_occur -gt 1 ]; then
			printf "%d" 1
			return
		fi
	done
	printf "%d" 0
}

print_summary()
{
	print_graph
	print_axis

	printf "\nResults\n"
	printf "  ⤷ Time average: %.3fs\n" "$AVERAGE_TIME"
	printf "  ⤷ Average: %.2f\n" "$AVERAGE_DIFF_LINES"
	printf "  ⤷ Min: %d\n" "$MIN_DIFF_LINES"
	printf "  ⤷ Max: %d\n" "$MAX_DIFF_LINES"
}

check_binary_files_are_executable()
{
	for bin in $@
	do
		[ ! -x $bin ] && print_usage_error_and_exit "'$bin' is not executable"
	done
}

[ $# -lt 3 ] && print_usage_and_exit
if ! echo $1 | grep -Eq "^[0-9]+$"; then print_usage_error_and_exit "'$1' is not a valid number"; fi
if ! echo $2 | grep -Eq "^(flow-(one|ten|thousand)|big|big-superposition)$"; then print_usage_error_and_exit "'$2' is not a valid type"; fi

TIMEOUT=10 #second
NB_TESTS="$1"
shift
TYPE="$1"
shift

check_binary_files_are_executable $@

MAP=".map"
MAP_BFR=".map_old"

touch $MAP ${MAP_BFR}

initialize_array_comp
initialize_arrays $@
run $@
[ ${#@} -eq 1 ] && print_summary || print_winners $@
