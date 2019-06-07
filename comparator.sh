#!/bin/sh

TYPE="$1"

[ "$2" ] && EXEC="$2" || EXEC="./lem-in"

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

function	run()
{
	printf "        usr   exp   diff\n"

	for i in {1..20}
	do
		generate_new_map
		max=`tail -n 1 $MAP | cut -d ':' -f 2 | bc`
		usr=`./$EXEC < $MAP | grep "^L" | wc -l | bc`
		diff=$((usr-max))
		printf "%4d : %4d  %4d    %+2d\n" $i $usr $max $diff
		let "COMP[$((10 + diff))]++"
		mv $MAP ${MAP_BFR}
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
run
print_summary

rm ${MAP_BFR}
