#!/bin/sh

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
		printf "%*s   " 10 $bin
	done
	printf "\n"
}

function	run()
{
	print_header $@

	for i in {1..25}
	do
		generate_new_map
		max=`tail -n 1 $MAP | cut -d ':' -f 2 | bc`
		printf "%4d : %4d  " $i $max
		j=0
		for bin in $@
		do
			usr=`$bin < $MAP | grep "^L" | wc -l | bc`
			if [ ${#bin} -lt 16 ]; then
				printf "%4d (%+3d)   "  $usr $((usr-max))
			else
				printf "%*s%4d (%+3d)   " $((${#bin} - 10)) "" $usr $((usr-max))
			fi
			((j++))
		done
		[ ${#@} -eq 1 ] && let "COMP[$((10 + usr - max))]++"
		mv $MAP ${MAP_BFR}
		printf "\n"
	done
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
}

touch $MAP ${MAP_BFR}

initialize_array_comp
run $@
[ ${#@} -eq 1 ] && print_summary

rm ${MAP_BFR}
