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

seq_start_at_zero()
{
	seq 0 $(($1 - 1))
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
	local i=0
	for bin in $@
	do
		ERROR[$i]=0
		COMP_DIFF[$i]=0
		COMP_NB_LINES[$i]=0
		COMP_TIME[$i]=0
		COMP_WIN_DIFF[$i]=0
		COMP_BIN[$i]="$bin"
		RESULTS[$i]=""
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
	printf "%*s${UNDERLINE} %*s exp  ${NC}" 7 "" $((2*${#@}))""
	for bin in $@
	do
		printf "${UNDERLINE}%*s  ${RESET}" $OUTPUT_LENGTH $bin
	done
	printf "\n"
}

get_value_winner_diff()
{
	local min="${COMP_DIFF[0]}"

	for i in `seq_start_at_zero ${#@}`
	do
		if [ ${ERROR[$i]} -eq 0 ]; then
			if [ "${COMP_DIFF[$i]}" -lt "$min" ];then
				min="${COMP_DIFF[$i]}"
			fi
		fi
	done
	printf "%d" $min
}

get_value_winner_time()
{
	local min="${COMP_TIME[0]}"

	for i in `seq_start_at_zero ${#@}`
	do
		if [ ${ERROR[$i]} -eq 0 ]; then
			local compare=`echo "${COMP_TIME[$i]} < $min" | bc -l`
			if  [ $compare -eq 1 ];then
				min="${COMP_TIME[$i]}"
			fi
		fi
	done
	printf "%.3f" $min
}

print_result_line()
{
	[ ${#@} -gt 1 ] && local value_winner_diff=`get_value_winner_diff $@`
	[ ${#@} -gt 1 ] && local value_winner_time=`get_value_winner_time $@`

	for i in `seq_start_at_zero ${#@}`
	do
		if [ ${ERROR[$i]} -eq 0 ]; then
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
				printf "%4d ${marker_diff}(%+3d)${NC} ${marker_time}0m%.3fs${NC}"  ${COMP_NB_LINES[$i]} ${COMP_DIFF[$i]} ${COMP_TIME[$i]}
			else
				printf "%*s%4d ${marker_diff}(%+3d)${NC} ${marker_time}0m%.3fs${NC}" $((${#COMP_BIN[$i]} - $OUTPUT_LENGTH)) "" ${COMP_NB_LINES[$i]} ${COMP_DIFF[$i]} ${COMP_TIME[$i]}
			fi
		else
			local width
			local msg="error"
			[ ${ERROR[$i]} -eq 2 ] && msg="timeout"
			[ ${#COMP_BIN[$i]} -lt $OUTPUT_LENGTH ] && width=$OUTPUT_LENGTH || width=${#COMP_BIN[$i]}
			printf "${RED}%*s${NC}" $width "$msg"
		fi
		printf "  "
	done
	printf "\n"
}

timeout_fct()
{
	local bin=$1
	local tmp_out=$2

	{ time $bin < $MAP; } > $tmp_out 2>&1 &
	local pid=$!
	sleep $TIMEOUT &
	local pid_sleep=$!
	while ps -p $pid_sleep > /dev/null
	do
		if ! ps -p $pid > /dev/null; then
			kill $pid_sleep > /dev/null 2>&1
		fi
	done
	if ps -p $pid > /dev/null; then
		kill $pid && killall `basename $bin` > /dev/null 2>&1
		return 2
	fi
	return 0
}

print_status_program()
{
	if [ $1 -eq 0 ]; then
		printf "${GREEN}✔ ${NC}"
	else
		printf "${RED}✗ ${NC}"
	fi
}

run()
{
	MAX_DIFF_LINES=-999999
	MIN_DIFF_LINES=999999
	local sum_diff_lines=0
	local sum_time=0.0
	local tmp_out=out.tmp

	print_header $@
	for test_i in `seq $NB_TESTS`
	do
		generate_new_map
		max=`tail -n 1 $MAP | cut -d ':' -f 2 | bc`
		printf "%4d : " $test_i
		COMP_NB_LINES[0]=$max
		for bin_j in `seq_start_at_zero ${#@}`
		do
			local bin=${COMP_BIN[$bin_j]}
			timeout_fct $bin $tmp_out 2> /dev/null
			ERROR[$bin_j]=$?
			print_status_program ${ERROR[$bin_j]}
			if [ ${ERROR[$bin_j]} -eq 0 ]; then
				usr=`grep "^L" $tmp_out | wc -l | bc`
				time=`grep real $tmp_out | cut -f2`
				time_nb=`echo $time | cut -c3-7 | bc -l`
				[ ${#@} -eq 1 ] && sum_time=`scale=3; echo "$sum_time + $time_nb" | bc -l`
				local diff=$((usr-max))
				COMP_DIFF[$bin_j]="$diff"
				COMP_NB_LINES[$bin_j]="$usr"
				COMP_TIME[$bin_j]="$time_nb"
				RESULTS[$bin_j]+="${ERROR[$bin_j]}:$usr:$diff:$time "
				[ ${#@} -eq 1 ] && [ "$diff" -lt "$MIN_DIFF_LINES" ] && MIN_DIFF_LINES="$diff"
				[ ${#@} -eq 1 ] && [ "$diff" -gt "$MAX_DIFF_LINES" ] && MAX_DIFF_LINES="$diff"
				[ ${#@} -eq 1 ] && sum_diff_lines=$((sum_diff_lines + diff))
				if [ ${#@} -eq 1 ]; then
					local index=$((10 + $usr - $max))
					[ $index -ge 0 ] && [ $index -le 20 ] &&  let "COMP[$((10 + usr - max))]++"
				fi
			else
				RESULTS[$bin_j]+="${ERROR[$bin_j]}:0:0:0 "
			fi
		done
		printf " %4d  " $max
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
	local max="${COMP_WIN_DIFF[0]}"
	for i in `seq_start_at_zero ${#@}`
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
	for i in `seq_start_at_zero ${#@}`
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
	for i in `seq_start_at_zero ${#@}`
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

print_average()
{
	for i in `seq_start_at_zero ${#@}`
	do
		echo "${RESULTS[$i]}"
	done
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
print_average $@
[ ${#@} -eq 1 ] && print_summary || print_winners $@
