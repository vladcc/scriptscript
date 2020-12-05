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
	leave 0
}

function full_chain
{
	_exec "diff -u generated_tests.c <(awk -f test_gen.awk test_cases.txt)"
	_exec "awk -f test_gen.awk test_cases.txt > generated_tests.c"
	_exec "gcc generated_tests.c -o generated_tests.bin -lm -Wall"
	_exec "./generated_tests.bin"
	_exec "rm ./generated_tests.bin"
}

function redirect_stdout
{
	_exec "awk -f test_gen.awk -vStdOut=stdout_redirect.txt test_cases.txt"
	_exec "diff -u generated_tests.c stdout_redirect.txt"
	_exec "rm ./stdout_redirect.txt"
}

function redirect_stderr
{
	eval "awk -f test_gen.awk -vStdErr=stderr_redirect.txt"
	
local L_ERR=\
"printf \"%s\n%s\n\" \"Use: test_gen.awk <input-file>\" \"Try 'test_gen.awk -vHelp=1' for more info\""
	_exec "diff -u stderr_redirect.txt <($L_ERR)"
	_exec "rm ./stderr_redirect.txt"
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

function _exec
{
	if [ ! -z "$G_ECHO" ]; then
		echo "$@"
	fi
	
	eval "$@" || err_quit "$@"
}

main "$@"
