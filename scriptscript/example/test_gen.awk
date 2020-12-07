#!/usr/bin/awk -f

function SCRIPT_NAME() {return "test_gen.awk"}
function SCRIPT_VERSION() {return "1.0"}

# <user_api>

@include "inc_user_events.awk"

# <user_print>
function print_ind_line(str, tabs) {print_tabs(tabs); print_puts(str)}
function print_ind_str(str, tabs) {print_tabs(tabs); print_stdout(str)}
function print_inc_indent() {print_set_indent(print_get_indent()+1)}
function print_dec_indent() {print_set_indent(print_get_indent()-1)}
function print_tabs(tabs,	 i, end) {
	end = tabs + print_get_indent()
	for (i = 1; i <= end; ++i)
		print_stdout("\t")
}
function print_new_lines(num,    i) {
	for (i = 1; i <= num; ++i)
		print_stdout("\n")
}

function print_set_indent(tabs) {__indent_count__ = tabs}
function print_get_indent(tabs) {return __indent_count__}
function print_puts(str) {__print_puts(str)}
function print_puts_err(str) {__print_puts_err(str)}
function print_stdout(str) {__print_stdout(str)}
function print_stderr(str) {__print_stderr(str)}
function print_set_stdout(str) {__print_set_stdout(str)}
function print_set_stderr(str) {__print_set_stderr(str)}
function print_get_stdout() {return __print_get_stdout()}
function print_get_stderr() {return __print_get_stderr()}
# </user_print>

# <user_error>
function error(msg) {__error(msg)}
function error_input(msg) {__error_input(msg)}
# </user_error>

# <user_exit>
function exit_success() {__exit_success()}
function exit_failure() {__exit_failure()}
# </user_exit>

# <user_utils>
function data_or_err() {
	if (NF < 2)
		error_input(sprintf("no data after '%s'", $1))
}

function reset_all() {
	reset_fname()
	reset_input()
	reset_match_with()
	reset_match_how()
	reset_generate()
}

function get_last_rule() {return __state_get()}

function save_fname(fname) {__fname_arr__[++__fname_num__] = fname}
function get_fname_count() {return __fname_num__}
function get_fname(num) {return __fname_arr__[num]}
function reset_fname() {delete __fname_arr__; __fname_num__ = 0}

function save_input(input) {__input_arr__[++__input_num__] = input}
function get_input_count() {return __input_num__}
function get_input(num) {return __input_arr__[num]}
function reset_input() {delete __input_arr__; __input_num__ = 0}

function save_match_with(match_with) {__match_with_arr__[++__match_with_num__] = match_with}
function get_match_with_count() {return __match_with_num__}
function get_match_with(num) {return __match_with_arr__[num]}
function reset_match_with() {delete __match_with_arr__; __match_with_num__ = 0}

function save_match_how(match_how) {__match_how_arr__[++__match_how_num__] = match_how}
function get_match_how_count() {return __match_how_num__}
function get_match_how(num) {return __match_how_arr__[num]}
function reset_match_how() {delete __match_how_arr__; __match_how_num__ = 0}

function save_generate(generate) {__generate_arr__[++__generate_num__] = generate}
function get_generate_count() {return __generate_num__}
function get_generate(num) {return __generate_arr__[num]}
function reset_generate() {delete __generate_arr__; __generate_num__ = 0}
# </user_utils>
# </user_api>
#==============================================================================#
#                        machine generated parser below                        #
#==============================================================================#
# <gen_parser>
# <gp_print>
function __print_set_stdout(f) {__gp_fout__ = ((f) ? f : "/dev/stdout")}
function __print_get_stdout() {return __gp_fout__}
function __print_stdout(str) {__print(str, __print_get_stdout())}
function __print_puts(str) {__print_stdout(sprintf("%s\n", str))}
function __print_set_stderr(f) {__gp_ferr__ = ((f) ? f : "/dev/stderr")}
function __print_get_stderr() {return __gp_ferr__}
function __print_stderr(str) {__print(str, __print_get_stderr())}
function __print_puts_err(str) {__print_stderr(sprintf("%s\n", str))}
function __print(str, file) {printf("%s", str) > file}
# </gp_print>
# <gp_exit>
function __exit_skip_end_set() {__exit_skip_end__ = 1}
function __exit_skip_end_clear() {__exit_skip_end__ = 0}
function __exit_skip_end_get() {return __exit_skip_end__}
function __exit_success() {__exit_skip_end_set(); exit(0)}
function __exit_failure() {__exit_skip_end_set(); exit(1)}
# </gp_exit>
# <gp_error>
function __error(msg) {
	__print_puts_err(sprintf("%s: error: %s", SCRIPT_NAME(), msg))
	__exit_failure()
}
function __error_input(msg) {
	__error(sprintf("file '%s', line %d: %s", FILENAME, FNR, msg))
}
function GP_ERROR_EXPECT() {return "'%s' expected, but got '%s' instead"}
function __error_parse(expect, got) {
	__error_input(sprintf(GP_ERROR_EXPECT(), expect, got))
}
# </gp_error>
# <gp_state_machine>
function __state_set(state) {__state__ = state}
function __state_get() {return __state__}
function __state_match(state) {return (__state_get() == state)}
function __state_transition(_next) {
	if (__state_match("")) {
		if (__R_FNAME() == _next) __state_set(_next)
		else __error_parse(__R_FNAME(), _next)
	}
	else if (__state_match(__R_FNAME())) {
		if (__R_INPUT() == _next) __state_set(_next)
		else __error_parse(__R_INPUT(), _next)
	}
	else if (__state_match(__R_INPUT())) {
		if (__R_MATCH_WITH() == _next) __state_set(_next)
		else __error_parse(__R_MATCH_WITH(), _next)
	}
	else if (__state_match(__R_MATCH_WITH())) {
		if (__R_MATCH_HOW() == _next) __state_set(_next)
		else __error_parse(__R_MATCH_HOW(), _next)
	}
	else if (__state_match(__R_MATCH_HOW())) {
		if (__R_INPUT() == _next) __state_set(_next)
		else if (__R_GENERATE() == _next) __state_set(_next)
		else __error_parse(__R_INPUT()"|"__R_GENERATE(), _next)
	}
	else if (__state_match(__R_GENERATE())) {
		if (__R_FNAME() == _next) __state_set(_next)
		else __error_parse(__R_FNAME(), _next)
	}
}
# </gp_state_machine>
# <gp_awk_rules>
function __R_FNAME() {return "fname"}
function __R_INPUT() {return "input"}
function __R_MATCH_WITH() {return "match_with"}
function __R_MATCH_HOW() {return "match_how"}
function __R_GENERATE() {return "generate"}

$1 == __R_FNAME() {__state_transition($1); on_fname(); next}
$1 == __R_INPUT() {__state_transition($1); on_input(); next}
$1 == __R_MATCH_WITH() {__state_transition($1); on_match_with(); next}
$1 == __R_MATCH_HOW() {__state_transition($1); on_match_how(); next}
$1 == __R_GENERATE() {__state_transition($1); on_generate(); next}
$0 ~ /^[[:space:]]*$/ {next} # ignore empty lines
$0 ~ /^[[:space:]]*#/ {next} # ignore comments
{__error_input(sprintf("'%s' unknown", $1))} # all else is error

function __init() {
	__print_set_stdout()
	__print_set_stderr()
	__exit_skip_end_clear()
}
BEGIN {
	__init()
	on_BEGIN()
}

END {
	if (!__exit_skip_end_get()) {
		if (__state_get() != __R_GENERATE())
			__error_parse(__R_GENERATE(), __state_get())
		else
			on_END()
	}
}
# </gp_awk_rules>
# </gen_parser>

# <user_input>
# Command line:
# -vScriptName=test_gen.awk
# -vScriptVersion=1.0
# Rules:
# fname -> input
# input -> match_with
# match_with -> match_how
# match_how -> input | generate
# generate -> fname
# </user_input>
# generated by scriptscript.awk 2.21
