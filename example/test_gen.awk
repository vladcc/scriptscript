#!/usr/bin/awk -f

# <user_events>
function handle_fname() {

}

function handle_input() {

}

function handle_match_with() {

}

function handle_match_how() {

}

function handle_generate() {

}

function awk_BEGIN() {

}

function awk_END() {

}
# </user_events>

# <print_lib>
function print_tab(tabs,    i) {
	for (i = 1; i <= tabs; ++i)
		printf("\t")
}

function print_new_line(new_lines,    i) {
	for (i = 1; i <= new_lines; ++i)
		printf("\n")
}

function print_string(str, tabs) {
	print_tab(tabs)
	printf(str)
}

function print_line(str, tabs) {
	print_string(str, tabs)
	print_new_line()
}
# </print_lib>

#==============================================================================#
#                        machine generated parser below                        #
#==============================================================================#

# <state_machine>
function error_raise(line_no, error_msg) {
	print "error: line " line_no ": " error_msg
	__error_happened__ = 1
	exit(1)
}
function parse_error(expected, got) {
	error_raise(NR, "'" expected "' expected, but got '" got "' instead")
}
function no_data_error(what) {
	error_raise(NR, "no data after '" what "'")
}
function state_transition(next_state) {
	if (__sm_now__ == "") {
		if (next_state == RULE_FNAME) {
			if (NF < 2) no_data_error(next_state)
			else __sm_now__ = next_state
		}
		else parse_error(RULE_FNAME, next_state)
	}
	else if (__sm_now__ == RULE_FNAME) {
		if (next_state == RULE_INPUT) {
			if (NF < 2) no_data_error(next_state)
			else __sm_now__ = next_state
		}
		else parse_error(RULE_INPUT, next_state)
	}
	else if (__sm_now__ == RULE_INPUT) {
		if (next_state == RULE_MATCH_WITH) {
			if (NF < 2) no_data_error(next_state)
			else __sm_now__ = next_state
		}
		else parse_error(RULE_MATCH_WITH, next_state)
	}
	else if (__sm_now__ == RULE_MATCH_WITH) {
		if (next_state == RULE_MATCH_HOW) {
			if (NF < 2) no_data_error(next_state)
			else __sm_now__ = next_state
		}
		else parse_error(RULE_MATCH_HOW, next_state)
	}
	else if (__sm_now__ == RULE_MATCH_HOW) {
		if (next_state == RULE_INPUT) {
			if (NF < 2) no_data_error(next_state)
			else __sm_now__ = next_state
		}
		else if (next_state == RULE_GENERATE) {
			__sm_now__ = next_state
		}
		else parse_error(RULE_INPUT "' or '" RULE_GENERATE, next_state)
	}
	else if (__sm_now__ == RULE_GENERATE) {
		if (next_state == RULE_FNAME) {
			if (NF < 2) no_data_error(next_state)
			else __sm_now__ = next_state
		}
		else parse_error(RULE_FNAME, next_state)
	}
}
# </state_machine>

# <input>
$0 ~ /^[[:space:]]*#/ {next} # match comments
$1 ~ RULE_FNAME {state_transition($1); handle_fname(); next}
$1 ~ RULE_INPUT {state_transition($1); handle_input(); next}
$1 ~ RULE_MATCH_WITH {state_transition($1); handle_match_with(); next}
$1 ~ RULE_MATCH_HOW {state_transition($1); handle_match_how(); next}
$1 ~ RULE_GENERATE {state_transition($1); handle_generate(); next}
$0 ~ /^$/ {next} # ignore empty lines
{error_raise(NR, "'" $1 "' unknown")}
# </input>

# <start>
BEGIN {
	RULE_FNAME = "fname"
	RULE_INPUT = "input"
	RULE_MATCH_WITH = "match_with"
	RULE_MATCH_HOW = "match_how"
	RULE_GENERATE = "generate"
	__error_happened__ = 0
	awk_BEGIN()
}
# </start>

# <end>
END {
	if (!__error_happened__) {
		if (__sm_now__ != RULE_GENERATE)
			error_raise(NR, "file should end with '" RULE_GENERATE "'")
		else
			awk_END()
	}
}
# </end>

