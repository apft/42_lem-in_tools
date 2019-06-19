#!/bin/sh

# Colors
RED='\x1b[1;31m'
GREEN='\x1b[1;32m'
YELLOW='\x1b[1;33m'
BLUE='\x1b[1;34m'
MAGENTA='\x1b[1;35m'
NC='\x1b[0m'

print_error(){
	printf "${RED}%s${NC}\n" "$1"
}

print_ok(){
	printf "${GREEN}%s${NC}\n" "$1"
}

print_warn(){
	printf "${YELLOW}%s${NC}\n" "$1"
}

print_test()
{
	printf "%s  - " "$1"
}

print_usage()
{
	echo "usage:"
	echo "\t$0 exec map"
	exit 1
}

rm_tmp_files()
{
	for file in $@
	do
		[ -f "$file" ] && rm $file
	done
}

clean_and_exit()
{
	#rm_tmp_files $@
	exit 1
}

check_usr_output()
{
	local nb_empty_line

	nb_empty_line=`grep -E "^$" $OUTPUT | wc -l | bc`
	if [ "$nb_empty_line" -eq 0 ]; then
		print_error "Missing empty line between map and solution"
		clean_and_exit $OUTPUT
	elif [ "$nb_empty_line" -ne 1 ]; then
		print_error "Too many empty lines"
		clean_and_exit $OUTPUT
	fi
}

extract_usr_output()
{
	local usr_map=$1
	local usr_sol=$2

	check_usr_output
	grep -vE "(^$|^L)" $OUTPUT > $usr_map
	grep "^L" $OUTPUT > $usr_sol
}

check_diff_output_map()
{
	local usr_map=$1
	local diff

	print_test "Check output map"
	diff=$(diff $MAP $usr_map)
	if [ "$diff" ]; then
		print_error "Output map is different from input"
		echo "diff -y input_map your_output_map"
		diff -y $MAP $usr_map
		return "1"
	else
		print_ok "success"
		return "0"
	fi
}

extract_room_command()
{
	local room=$1

	grep -A 1 "##$room" $MAP | tail -n 1 | cut -d ' ' -f 1
}

check_only_one_move_per_ant()
{
	local line=$@
	local duplicate

	duplicate=`echo "$line" | grep -Eo "L[0-9]+" | sort | uniq -d`
	if [ "$duplicate" ]; then
		print_error "Too many moves for at least an ant"
		echo "ant nbr: {`echo $duplicate | tr -d 'L' | tr ' ' ','`} in line: '$line'"
		return "1"
	fi
	return "0"
}

check_only_one_ant_per_room()
{
	local room_end=$1
	shift
	local line=$@
	local duplicate

	duplicate=`echo "$line" | grep -Eo "\-[A-Za-z0-9_]+[[:>:]]" | cut -c 2- | sort | grep -v "$room_end" | uniq -d`
	if [ "$duplicate" ]; then
		print_error "Too many ants in one room"
		echo "room: {`echo $duplicate | tr -d 'L' | tr ' ' ','`} in line: '$line'"
		return "1"
	fi
	return "0"
}

check_usr_solution()
{
	local file_sol=$1
	local room_end=$2

	print_test "Check one ant per line and one room per line (beside room_end)"
	while read line
	do
		check_only_one_ant_per_room $room_end $line
		[ $? -eq 1 ] && return "1"
		check_only_one_move_per_ant $line
		[ $? -eq 1 ] && return "1"
	done < $file_sol
	print_ok "success"
	return 0
}

extract_path_ant()
{
	local usr_solution=$1
	local ant=$2

	grep -Eo "[[:<:]]$ant[[:>:]]-[A-Za-z0-9_]+" $usr_solution | cut -d '-' -f 2 | tr '\n' ' ' | sed 's/ $//'
}

check_path_exists()
{
	local room_start=$1
	local room_end=$2
	shift 2
	local path=$@
	local prev_room=$room_start

	for room in $path
	do
		grep -E "(^$prev_room-$room$|^$room-$prev_room$)" $MAP > /dev/null
		if [ $? -ne 0 ]; then
			print_error "Link between rooms {$prev_room-$room} does not exist"
			return 1
		fi
		prev_room=$room
	done
	if [ "$room" != "$room_end" ]; then
		print_error "Path does not end on room_end {$room_end}"
		return 1
	fi
	return 0
}

extract_paths()
{
	local usr_solution=$1
	local usr_paths=$2
	local room_start=$3
	local room_end=$4
	local ants_first_line=`head -n 1 $usr_solution | tr ' ' '\n' | cut -d '-' -f 1`

	print_test "Check paths"
	#echo "`echo $ants_first_line | wc -w | bc` paths found"
	[ -f "$usr_paths" ] && rm $usr_paths
	local i=0
	#echo "paths found: {id: (length) path}"
	for ant in $ants_first_line
	do
		local path=`extract_path_ant $usr_solution $ant`
		check_path_exists $room_start $room_end $path
		if [ $? -eq 1 ]; then
			print_error "Path {$path} does not exists"
			return 1
		fi
		local length=`echo $path | wc -w | bc`
		#printf " %2d: (%2d)  %s\n" $i $length "$path"
		echo "$i:$length:$path" >> $usr_paths
		((i++));
	done
	print_ok "success"
	return 0
}

check_path_ants()
{
	local usr_solution=$1
	local usr_paths=$2
	local nb_ants=$3

	print_test "Check path for each ant"
	for i in `seq $nb_ants`
	do
		local path=`extract_path_ant $usr_solution "L$i"`
		grep -E ":$path$" $usr_paths > /dev/null
		if [ $? -ne 0 ]; then
		   	print_error "Path followed by ant $ant does not exist {$path}"
			return 1
		fi
	done
	print_ok "success"
	return 0
}

check_all_ants_reach_end()
{
	local usr_solution=$1
	local room_end=$2
	local nb_ants=$3

	print_test "Check all ants reach room_end"
	local nb_ants_in_end=`grep -o "$room_end" $usr_solution | wc -l | bc`
	if [ $nb_ants -ne $nb_ants_in_end ]; then
		local txt=`[ $nb_ants_in_end -lt $nb_ants ] && printf "few" || printf "many"`
		print_error "Too $txt ants reach room_end (reach: $nb_ants_in_end, expected: $nb_ants)"
		return 1
	fi
	print_ok "success"
	return 0
}

run_main()
{
	local usr_map=".usr_map"
	local usr_solution=".usr_solution"
	local usr_paths=".usr_paths"
	local files="$usr_map $usr_solution $usr_paths"
	local room_start=`extract_room_command "start"`
	local room_end=`extract_room_command "end"`
	local nb_ants=`head -n 1 $MAP`

	extract_usr_output $usr_map $usr_solution
	check_diff_output_map $usr_map
	[ $? -eq 1 ] && clean_and_exit $OUTPUT $files

	check_usr_solution $usr_solution $room_end
	[ $? -eq 1 ] && clean_and_exit $OUTPUT $files

	extract_paths $usr_solution $usr_paths $room_start $room_end
	[ $? -eq 1 ] && clean_and_exit $OUTPUT $files
	check_path_ants $usr_solution $usr_paths $nb_ants
	[ $? -eq 1 ] && clean_and_exit $OUTPUT $files

	check_all_ants_reach_end $usr_solution $room_end $nb_ants
	[ $? -eq 1 ] && clean_and_exit $OUTPUT $files

	rm_tmp_files $OUTPUT $files
}

[ $# -ne 2 ] && print_usage
EXEC="$1"
MAP="$2"
OUTPUT=".out_checker"
$EXEC < $MAP > $OUTPUT

[ $? -eq 0 ] && run_main
