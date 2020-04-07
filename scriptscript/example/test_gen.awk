#!/usr/bin/awk -f

# <user_events>
function handle_fname() {
	data_or_err()
	save_fname($2)

}

function handle_input() {
	data_or_err()
	save_input($2)

}

function handle_match_with() {
	data_or_err()
	save_match_with($2)

}

function handle_match_how() {
	data_or_err()
    
    MATCH_HOW_EQ_SRC = "=="
    MATCH_HOW_EQ_NAME = "equals"
    MATCH_HOW_LT_SRC = "<"
    MATCH_HOW_LT_NAME = "less_than"

    # enforce only == and < comparison allowed in tests
    if ($2 == MATCH_HOW_EQ_SRC)
        $2 = MATCH_HOW_EQ_NAME
    else if ($2 == MATCH_HOW_LT_SRC)
        $2 = MATCH_HOW_LT_NAME
    else 
        input_error("unknown match_how: '" $2 "'")
        
	save_match_how($2)
}

function output_if_test(comp_op, comp_name) {
    # print test failure detection and messages
    print_line("if (!(result " comp_op " node->match_with))")
    print_line("{")
    print_inc_indent()
    
    tmp = sprintf("\"%s\", %s", "index of failed test: %d\\n", "i")
    print_line("printf(" tmp ");")
    
    tmp = sprintf("\"%s\", %s, %s",
        "function %s(), line %d\\n", "__func__", "__LINE__")
    print_line("printf(" tmp ");")
    
    tmp = sprintf("\"%s\", %s",
        "input %d, result %d, expected " comp_name " %d\\n",
        "node->input, result, node->match_with") 
    print_line("printf(" tmp ");")
    print_line("exit(EXIT_FAILURE);")
    
    print_dec_indent()
    print_line("}")
}

function handle_generate() {
    TEST_STRUCT_TYPE = "test_node"
    TEST_TABLE_NAME = "test_tbl"
    TEST_NODE_TYPE = "test_node"
    FNAME = get_fname(get_fname_count())
    all = get_input_count()
    
    # print test function
    print_line("static void test_" FNAME "(void)")
    print_line("{")    
    print_inc_indent()
    
    # print struct declaration
    print_line("typedef struct " TEST_STRUCT_TYPE " {")
    print_line("int input;", 1)
    print_line("int match_with;", 1)
    print_line("int match_how;", 1)
    print_line("} " TEST_STRUCT_TYPE ";\n")
    
    # print different types of comparison
    print_line("enum {" MATCH_HOW_EQ_NAME " = 1, " MATCH_HOW_LT_NAME " = 2};")
    print_line()
    
    # print test table definition
    print_line(TEST_STRUCT_TYPE " " TEST_TABLE_NAME "[] = {")
    
    for (i = 1; i <= all; ++i) {
        tmp = sprintf("{.input = %s, .match_with = %s, .match_how = %s},",
            get_input(i), get_match_with(i), get_match_how(i))
        print_line(tmp, 1)
    }
    print_line("};\n")
    
    # print test loop
    print_line("int result;")
    print_line(TEST_NODE_TYPE " * node;")
    
    tmp = sprintf("for (int i = 0; i < sizeof(%s)/sizeof(*%s); ++i)",
        TEST_TABLE_NAME, TEST_TABLE_NAME)
        
    print_line(tmp)
    print_line("{")
    print_inc_indent()
    
    print_line("node = " TEST_TABLE_NAME "+i;")
    print_line("result = " FNAME "(node->input);")
    
    # print comparison switch
    print_line("switch(node->match_how)")
    print_line("{")
    print_inc_indent()
    
    print_line("case " MATCH_HOW_EQ_NAME ":")
    print_inc_indent()
    output_if_test(MATCH_HOW_EQ_SRC, MATCH_HOW_EQ_NAME)
    print_line("break;")
    print_dec_indent()
    
    print_line("case " MATCH_HOW_LT_NAME ":")
    print_inc_indent()
    output_if_test(MATCH_HOW_LT_SRC, MATCH_HOW_LT_NAME)
    print_line("break;")
    print_dec_indent()
    
    print_line("default:")
    print_inc_indent()
    print_line("break;")
    print_dec_indent()
    
    print_dec_indent()
    print_line("}")
    
    print_dec_indent()
    print_line("}")
    print_dec_indent()
    print_line("}")
    print_line()

    # do not reset fname so all fnames are available for awk_END()
	#reset_fname()
	reset_input()
	reset_match_with()
	reset_match_how()
}

function awk_BEGIN() {
    print_line("// machine generated file")
    
    # print headers
    print_line("#include <stdio.h>")
    print_line("#include <math.h>")
    print_line("#include <stdlib.h>")
    print_line()
    
    # print intfact()
    print_line("int intfact(int n)")
    print_line("{")
    print_inc_indent()
    print_line("if (n < 0 || n > 12) return -1;")
    print_line("if (n < 2) return 1;")
    print_line("return n * intfact(n-1);")
    print_dec_indent()
    print_line("}")
    print_line()
    
    # print intsqrt()
    print_line("int intsqrt(int n)")
    print_line("{")
    print_inc_indent()
    print_line("if (n < 0) return -1;")
    print_line("double sqroot = sqrt(n);")
    print_line("if (fabs(floor(sqroot)) == fabs(sqroot)) return sqroot;")
    print_line("return -2;")
    print_dec_indent()
    print_line("}")
    print_line()
}

function awk_END() {
	if (get_last_rule() != __R_GENERATE)
		in_error("last read rule not last declared")
        
     # print main()
    print_line("int main(void)")
    print_line("{")
    print_inc_indent()
    
    end = get_fname_count();
    for (i = 1; i <= end; ++i)
        print_line("test_" get_fname(i) "();")
    
    print_line("return 0;")
    print_dec_indent()
    print_line("}")
}

function in_error(error_msg) {
	__error_raise(error_msg)
}
# </user_events>

# <print_lib>
function print_set_indent(tabs) {__base_indent__ = tabs}
function print_get_indent() {return __base_indent__}
function print_inc_indent() {print_set_indent(print_get_indent()+1)}
function print_dec_indent() {print_set_indent(print_get_indent()-1)}
function print_string(str, tabs) {print_tabs(tabs); printf("%s", str)}
function print_line(str, tabs) {print_string(str, tabs); print_new_lines(1)}
function print_tabs(tabs,    i, end) {
	end = tabs + print_get_indent()
	for (i = 1; i <= end; ++i)
		printf("\t")
}
function print_new_lines(new_lines,    i) {
	for (i = 1; i <= new_lines; ++i)
		printf("\n")
}
# </print_lib>

# <utils>
function data_or_err() {
	if (NF < 2)
		__error_raise(sprintf("no data after '%s'", $1))
}

function reset_all() {
	reset_fname()
	reset_input()
	reset_match_with()
	reset_match_how()
	reset_generate()
}

function get_last_rule() {return __state}

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
# </utils>

#==============================================================================#
#                        machine generated parser below                        #
#==============================================================================#

# <state_machine>
function __error_raise(error_msg) {
	printf("error: %s, line %d: %s\n", FILENAME, FNR, error_msg) > "/dev/stderr"
	__error_happened = 1
	exit(1)
}
function __parse_error(expct, got) {
	__error_raise(sprintf("'%s' expected, but got '%s' instead", expct, got))
}
function __state_transition(__next) {
	if (__state == "") {
		if (__next == __R_FNAME) __state = __next
		else __parse_error(__R_FNAME, __next)
	}
	else if (__state == __R_FNAME) {
		if (__next == __R_INPUT) __state = __next
		else __parse_error(__R_INPUT, __next)
	}
	else if (__state == __R_INPUT) {
		if (__next == __R_MATCH_WITH) __state = __next
		else __parse_error(__R_MATCH_WITH, __next)
	}
	else if (__state == __R_MATCH_WITH) {
		if (__next == __R_MATCH_HOW) __state = __next
		else __parse_error(__R_MATCH_HOW, __next)
	}
	else if (__state == __R_MATCH_HOW) {
		if (__next == __R_INPUT) __state = __next
		else if (__next == __R_GENERATE) __state = __next
		else __parse_error(__R_INPUT"|"__R_GENERATE, __next)
	}
	else if (__state == __R_GENERATE) {
		if (__next == __R_FNAME) __state = __next
		else __parse_error(__R_FNAME, __next)
	}
}
# </state_machine>

# <input>
$1 == __R_FNAME {__state_transition($1); handle_fname(); next}
$1 == __R_INPUT {__state_transition($1); handle_input(); next}
$1 == __R_MATCH_WITH {__state_transition($1); handle_match_with(); next}
$1 == __R_MATCH_HOW {__state_transition($1); handle_match_how(); next}
$1 == __R_GENERATE {__state_transition($1); handle_generate(); next}
$0 ~ /^[[:space:]]*$/ {next} # ignore empty lines
$0 ~ /^[[:space:]]*#/ {next} # ignore comments
{__error_raise("'" $1 "' unknown")} # all else is error
# </input>

# <start>
BEGIN {
	__R_FNAME = "fname"
	__R_INPUT = "input"
	__R_MATCH_WITH = "match_with"
	__R_MATCH_HOW = "match_how"
	__R_GENERATE = "generate"
	__error_happened = 0
	awk_BEGIN()
}
# </start>

# <end>
END {
	if (!__error_happened)
		awk_END()
}
# </end>

# <user_source>
# fname -> input
# input -> match_with
# match_with -> match_how
# match_how -> input | generate
# generate -> fname
# </user_source>

# generated by scriptscript v2.11
