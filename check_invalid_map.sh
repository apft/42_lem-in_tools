#!/bin/sh

if [ -f colors.sh ]; then
	. colors.sh
fi

PROJECT_PATH=../lem_in

MAP_PATH=maps/invalid
INPUT_DATA=data_error.txt

TEST_TMP=test_temp

print_ok()
{
	printf "${GREEN}%s${RESET}" $1
}

print_error()
{
	printf "${RED}%s${RESET}" $1
}

run_test()
{
	local name=`echo $1 | cut -d';' -f1`
	local map=`echo $1 | cut -d';' -f2`

	${PROJECT_PATH}/lem-in < ${MAP_PATH}/${map} 2> ${TEST_TMP}
	local output=`cat -e ${TEST_TMP}`
	if [ "${output}" = "ERROR$" ]; then
		print_ok "Good!"
	else
		print_error "Boooo!"
	fi
}

while read line
do
	run_test ${line}
done < ${INPUT_DATA}
