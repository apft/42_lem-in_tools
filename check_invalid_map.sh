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
	printf "${GREEN}%s${RESET}" "$1"
}

print_error()
{
	printf "${RED}%s${RESET}" "$1"
}

print_warning()
{
	printf "${YELLOW}%s${RESET}" "$1"
}

run_test()
{
	local name=`echo $@ | cut -d';' -f1`
	local map=`echo $@ | cut -d';' -f2`

	printf "%-50s" "$name"
	if [ -f "${MAP_PATH}/${map}" ];then
		${PROJECT_PATH}/lem-in -e < "${MAP_PATH}/${map}" > /dev/null 2> ${TEST_TMP}
		local output=`cat -e ${TEST_TMP}`
		if [ "${output:0:5}" = "ERROR" ]; then
			print_ok "Good!"
		else
			print_error "Booo!"
		fi
		printf "%5s%-60s" "" "`cat ${TEST_TMP}`"
	else
		print_warning "File not found"
	fi
	printf "\n"
}

while read line
do
	run_test ${line}
done < ${INPUT_DATA}
#rm $TEST_TMP
