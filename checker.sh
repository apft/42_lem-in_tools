#!/bin/sh

# recuperer le nombre de chemin : 1ere ligne
# creer le tableau de longeur des chemind
# pour le reste des fourmis, checker que la longeur de son chemin est coherente
# verifier qu'une fourmi ne se deplace qu'une fois par ligne
# verifier que le chemin est valide
# lecture ligne a ligne de la sortie du prgm ./lem-in

# Colors
RED='\x1b[1;31m'
GREEN='\x1b[1;32m'
YELLOW='\x1b[1;33m'
BLUE='\x1b[1;34m'
MAGENTA='\x1b[1;35m'
NC='\x1b[0m'

# Print error message
print_error(){
	printf "${RED}%s${NC}\n" "$1"
}

# Print message ok
print_ok(){
	printf "${GREEN}%s${NC}\n" "$1"
}

# Print warning message
print_warn(){
	printf "${YELLOW}%s${NC}\n" "$1"
}

function print_usage()
{
	echo "usage:"
	echo "\t$0 exec map"
	exit 1
}

function rm_tmp_files()
{
	for file in $@
	do
		[ -f "$file" ] && rm $file
	done
}

function clean_and_exit()
{
	rm_tmp_files $@
	exit 1
}

function extract_command()
{
	local room=$1

	grep -A 1 "##$room" $MAP | tail -n 1 | cut -d ' ' -f 1
}

function check_usr_output()
{
	local nb_empty_line

	nb_empty_line=`grep -o "^$" $OUTPUT | wc -l | bc`
	if [ "$nb_empty_line" -eq 0 ]; then
		print_error "Missing empty line between map and solution"
		clean_and_exit $OUTPUT
	elif [ "$nb_empty_line" -ne 1 ]; then
		print_error "Too many empty lines"
		clean_and_exit $OUTPUT
	fi
}

function extract_usr_output()
{
	local map=$1
	local sol=$2

	check_usr_output
	grep -vE "(^$|^L)" $OUTPUT > $map
	grep "^L" $OUTPUT > $sol
}

function check_diff_output_map()
{
	local map
	local diff

	map=$1
	diff=$(diff $MAP $map)
	if [ "$diff" ]; then
		print_error "Output map is different from input"
		echo "diff -y input_map your_output_map"
		diff -y $MAP $map
		return "0"
	else
		print_ok "Output map is correct"
		return "1"
	fi
}

function print_paths()
{
	for i in `seq ${nb_path}`
	do
		printf "%d: " $i
		grep -E -o "L$i-[A-Z][a-z_]{2}[0-9]" $OUTPUT | cut -d '-' -f 2 | tr '\n' ' '
		printf "\n"
	done
}

function length()
{
	local	index="$1"
	grep "L${index}-" $OUTPUT | wc -l | bc
}

function run_main()
{
	local usr_map
	local usr_solution
	local nb_ants
	local room_start
	local room_end
	local nb_path
	local path_length

	usr_map=".usr_map"
	usr_solution=".usr_solution"

	extract_usr_output $usr_map $usr_solution
	check_diff_output_map $usr_map
	[ "$?" == 0 ] && clean_and_exit $OUTPUT $usr_map $usr_solution

	nb_ants=`head -n 1 $MAP`
	nb_path=`grep "^L" $OUTPUT | head -n 1 | grep -o "L" | wc -l | bc`

	room_start=`extract_command "start"`
	room_end=`extract_command "end"`
	echo "start: ${room_start}"
	echo "end: ${room_end}"

	echo "ants: ${nb_ants}"
	echo "path: ${nb_path}"

	print_paths

	for i in `seq ${nb_path}`
	do
		path_length[$i]=`length $i`
	done

	echo "path length: ${path_length[@]}"

	for i in `seq ${nb_ants}`
	do
		length=`length $i`
		echo "${path_length[@]}" | grep "$length" > /dev/null
		if [ $? -ne 0 ]; then
			echo "error: ant $i goes through a path length of $length"
			exit
		fi
	done

	rm_tmp_files $OUTPUT
}

[ $# -ne 2 ] && print_usage
EXEC="$1"
MAP="$2"
OUTPUT=".out_checker"
$EXEC < $MAP > $OUTPUT

run_main
