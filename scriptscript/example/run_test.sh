#!/bin/bash

set -u

G_ECHO=""

function main
{
	if [ "$#" -gt 0 ]; then
		G_ECHO="yes"
	fi
	
	enter
	full_chain
	redirect_stdout
	redirect_stderr
	test_errors
	leave 0
}

function test_errors
{
	local L_FERR="./stderr_redirect.txt"
	local L_AWK="awk -f test_gen.awk -vStdErr=stderr_redirect.txt"
	local L_IN_AWK=""
	local L_ACC=""
	
L_IN_AWK="./bad_input/bad_1.txt"
L_ACC=\
"test_gen.awk: error: file './bad_input/bad_1.txt', line 2: 'fname' expected, but got 'input' instead"
	_exec "$L_AWK $L_IN_AWK > /dev/null"
	_exec_q "diff -u $L_FERR <(echo \"$L_ACC\")"

L_IN_AWK="./bad_input/bad_2.txt"
L_ACC=\
"test_gen.awk: error: file './bad_input/bad_2.txt', line 3: 'input' expected, but got 'match_with' instead"
	_exec "$L_AWK $L_IN_AWK > /dev/null"
	_exec_q "diff -u $L_FERR <(echo \"$L_ACC\")"

L_IN_AWK="./bad_input/bad_3.txt"
L_ACC=\
"test_gen.awk: error: file './bad_input/bad_3.txt', line 4: 'match_with' expected, but got 'match_how' instead"
	_exec "$L_AWK $L_IN_AWK > /dev/null"
	_exec_q "diff -u $L_FERR <(echo \"$L_ACC\")"
	
L_IN_AWK="./bad_input/bad_4.txt"
L_ACC=\
"test_gen.awk: error: file './bad_input/bad_4.txt', line 5: 'match_how' expected, but got 'generate' instead"
	_exec "$L_AWK $L_IN_AWK > /dev/null"
	_exec_q "diff -u $L_FERR <(echo \"$L_ACC\")"
	
L_IN_AWK="./bad_input/bad_5.txt"
L_ACC=\
"test_gen.awk: error: file './bad_input/bad_5.txt', line 5: 'generate' expected, but got 'match_how' instead"
	_exec "$L_AWK $L_IN_AWK > /dev/null"
	_exec_q "diff -u $L_FERR <(echo \"$L_ACC\")"
	
L_IN_AWK="./bad_input/bad_or.txt"
L_ACC=\
"test_gen.awk: error: file './bad_input/bad_or.txt', line 5: 'input|generate' expected, but got 'match_with' instead"
	_exec "$L_AWK $L_IN_AWK > /dev/null"
	_exec_q "diff -u $L_FERR <(echo \"$L_ACC\")"
	
L_IN_AWK="./bad_input/bad_unknown.txt"
L_ACC=\
"test_gen.awk: error: file './bad_input/bad_unknown.txt', line 4: 'random' unknown"
	_exec "$L_AWK $L_IN_AWK > /dev/null"
	_exec_q "diff -u $L_FERR <(echo \"$L_ACC\")"
	
	_exec_q "rm $L_FERR"
}

function full_chain
{
	_exec_q "diff -u generated_tests.c <(awk -f test_gen.awk test_cases.txt)"
	_exec_q "awk -f test_gen.awk test_cases.txt > generated_tests.c"
	_exec_q "gcc generated_tests.c -o generated_tests.bin -lm -Wall"
	_exec_q "./generated_tests.bin"
	_exec_q "rm ./generated_tests.bin"
}

function redirect_stdout
{
	_exec_q "awk -f test_gen.awk -vStdOut=stdout_redirect.txt test_cases.txt"
	_exec_q "diff -u generated_tests.c stdout_redirect.txt"
	_exec_q "rm ./stdout_redirect.txt"
}

function redirect_stderr
{	
	_exec "awk -f test_gen.awk -vStdErr=stderr_redirect.txt"
	
local L_ERR=\
"printf \"%s\n%s\n\" \"Use: test_gen.awk <input-file>\" \"Try 'test_gen.awk -vHelp=1' for more info\""
	_exec_q "diff -u stderr_redirect.txt <($L_ERR)"
	_exec_q "rm ./stderr_redirect.txt"
}

function enter
{
	pushd "$(realpath $(dirname $0))" > /dev/null
}

function leave
{
	popd > /dev/null
	exit "$1"
}

function err_quit
{
	local L_EXIT="$?"
	echo "'$@' failed with exit code $L_EXIT" > /dev/stderr
	leave "$L_EXIT"
}

function _exec_q
{
	if [ ! -z "$G_ECHO" ]; then
		echo "$@"
	fi
	
	eval "$@" || err_quit "$@"
}

function _exec
{
	if [ ! -z "$G_ECHO" ]; then
		echo "$@"
	fi
	
	eval "$@"
}

main "$@"
