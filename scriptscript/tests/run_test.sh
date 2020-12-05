#!/bin/bash

set -u

readonly G_TARGET="scriptscript.awk"
readonly G_BASE_DIR="$(realpath $(dirname $0))"
readonly G_TEST_RESULT="./test_result.txt"
readonly G_TEST_ACCEPT="./test_accept.txt"
readonly G_SCRSCR="../${G_TARGET}"

readonly G_SUCCESS='[ $? -eq 0 ]'
readonly G_FAILURE='[ $? -ne 0 ]'
readonly G_FOO="foo.awk"
readonly G_VSCR_NM="-vScriptName=${G_FOO}"
readonly G_VSCR_VR="-vScriptVersion=xx.xx"

readonly G_RULES_OK="./test_rules_ok.txt"
G_INPUT_FILE=""
G_REDIRECT=""

function main
{
	enter
	
	> "$G_TEST_RESULT"
	
	test_generator
	test_generated
	
	check
	
	leave 0
}

function check
{
	diff -u "$G_TEST_ACCEPT" "$G_TEST_RESULT"
	assert "$G_SUCCESS"
	
	rm "$G_TEST_RESULT" 
}

function test_generated
{
	local L_GENERATED="./$G_FOO"
	set_redirect "> $L_GENERATED"
	run_generator_on_file "$G_RULES_OK"
	
	set_input_file ""
	set_redirect "2>>$G_TEST_RESULT"
	run "$L_GENERATED"
	assert "$G_FAILURE"
	
	set_input_file "two files"
	run "$L_GENERATED"
	assert "$G_FAILURE"
	
	set_redirect "1>>$G_TEST_RESULT"
	run "$L_GENERATED" "-vVersion=1"
	assert "$G_SUCCESS"
	run "$L_GENERATED" "-vHelp=1"
	assert "$G_SUCCESS"
	
	set_input_file ""
	run "$L_GENERATED" "-vVersion=1"
	assert "$G_SUCCESS"
	run "$L_GENERATED" "-vHelp=1"
	assert "$G_SUCCESS"
	
	set_redirect "2>>$G_TEST_RESULT"
	set_input_file "empty"
	run "$L_GENERATED"
	assert "$G_FAILURE"
	
	rm "$L_GENERATED"
}

function test_generator
{
	set_redirect "2>>$G_TEST_RESULT"
	
	run "$G_SCRSCR"
	assert "$G_FAILURE"
	
	set_input_file "two files"
	run "$G_SCRSCR"
	assert "$G_FAILURE"
	
	set_input_file "dummy"
	run "$G_SCRSCR"
	assert "$G_FAILURE"
	
	run "$G_SCRSCR $G_VSCR_NM"
	assert "$G_FAILURE"
	
	run_generator_on_file "empty"
	assert "$G_FAILURE"
	
	run_generator_on_file "test_rules_bad_1.txt"
	assert "$G_FAILURE"
	
	run_generator_on_file "test_rules_bad_2.txt"
	assert "$G_FAILURE"
	
	run_generator_on_file "test_rules_bad_3.txt"
	assert "$G_FAILURE"
	
	run_generator_on_file "test_rules_bad_4.txt"
	assert "$G_FAILURE"
	
	run_generator_on_file "test_rules_bad_5.txt"
	assert "$G_FAILURE"
	
	set_redirect "1>>$G_TEST_RESULT"
	run_generator_on_file "$G_RULES_OK"
	assert "$G_SUCCESS"
}

function enter
{
	pushd "$G_BASE_DIR" > /dev/null
}

function leave
{
	popd > /dev/null
	exit "$1"
}

function run_generator_on_file
{
	set_input_file "$@"
	run "$G_SCRSCR $G_VSCR_NM $G_VSCR_VR"
}

function run
{
	local L_RUN_LINE="awk -f $@ $G_INPUT_FILE"
	echo "## $L_RUN_LINE ${G_REDIRECT//>/\\>}" >> "$G_TEST_RESULT"
	eval "$L_RUN_LINE $G_REDIRECT"
}

function set_redirect
{
	G_REDIRECT="$@"
}

function set_input_file
{
	G_INPUT_FILE="$@"
}

function assert
{
	eval "$@"
	if [ $? -ne 0 ]; then
		echo "$(caller 0) '${FUNCNAME[0]} $@' failed"
		leave 1
	fi
}

main "$@"
