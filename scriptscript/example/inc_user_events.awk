# <user_events>
function on_fname() {
	data_or_err()
	save_fname($2)

}

function on_input() {
	data_or_err()
	save_input($2)

}

function on_match_with() {
	data_or_err()
	save_match_with($2)

}

function MATCH_HOW_EQ_SRC() {return "=="}
function MATCH_HOW_EQ_NAME() {return "equals"}
function MATCH_HOW_LT_SRC() {return "<"}
function MATCH_HOW_LT_NAME() {return "less_than"}

function on_match_how() {
	data_or_err()

    # enforce only == and < comparison allowed in tests
    if ($2 == MATCH_HOW_EQ_SRC())
        $2 = MATCH_HOW_EQ_NAME()
    else if ($2 == MATCH_HOW_LT_SRC())
        $2 = MATCH_HOW_LT_NAME()
    else 
        input_error("unknown match_how: '" $2 "'")
        
	save_match_how($2)
}

function output_if_test(comp_op, comp_name) {
    # print test failure detection and messages
    print_ind_line("if (!(result " comp_op " node->match_with))")
    print_ind_line("{")
    print_inc_indent()
    
    tmp = sprintf("\"%s\", %s", "index of failed test: %d\\n", "i")
    print_ind_line("printf(" tmp ");")
    
    tmp = sprintf("\"%s\", %s, %s",
        "function %s(), line %d\\n", "__func__", "__LINE__")
    print_ind_line("printf(" tmp ");")
    
    tmp = sprintf("\"%s\", %s",
        "input %d, result %d, expected " comp_name " %d\\n",
        "node->input, result, node->match_with") 
    print_ind_line("printf(" tmp ");")
    print_ind_line("exit(EXIT_FAILURE);")
    
    print_dec_indent()
    print_ind_line("}")
}

function TEST_STRUCT_TYPE() {return "test_node"}
function TEST_TABLE_NAME() {return "test_tbl"}
function TEST_NODE_TYPE() {return "test_node"}

function on_generate(    fname) {
    
    fname = get_fname(get_fname_count())
    all = get_input_count()
    
    # print test function
    print_ind_line("static void test_" fname "(void)")
    print_ind_line("{")    
    print_inc_indent()
    
    # print struct declaration
    print_ind_line("typedef struct " TEST_STRUCT_TYPE() " {")
    print_ind_line("int input;", 1)
    print_ind_line("int match_with;", 1)
    print_ind_line("int match_how;", 1)
    print_ind_line("} " TEST_STRUCT_TYPE() ";\n")
    
    # print different types of comparison
    print_ind_line("enum {" MATCH_HOW_EQ_NAME() " = 1, " MATCH_HOW_LT_NAME() " = 2};")
    print_ind_line()
    
    # print test table definition
    print_ind_line(TEST_STRUCT_TYPE() " " TEST_TABLE_NAME() "[] = {")
    
    for (i = 1; i <= all; ++i) {
        tmp = sprintf("{.input = %s, .match_with = %s, .match_how = %s},",
            get_input(i), get_match_with(i), get_match_how(i))
        print_ind_line(tmp, 1)
    }
    print_ind_line("};\n")
    
    # print test loop
    print_ind_line("int result;")
    print_ind_line(TEST_NODE_TYPE() " * node;")
    
    tmp = sprintf("for (int i = 0; i < sizeof(%s)/sizeof(*%s); ++i)",
        TEST_TABLE_NAME(), TEST_TABLE_NAME())
        
    print_ind_line(tmp)
    print_ind_line("{")
    print_inc_indent()
    
    print_ind_line("node = " TEST_TABLE_NAME() "+i;")
    print_ind_line("result = " fname "(node->input);")
    
    # print comparison switch
    print_ind_line("switch(node->match_how)")
    print_ind_line("{")
    print_inc_indent()
    
    print_ind_line("case " MATCH_HOW_EQ_NAME() ":")
    print_inc_indent()
    output_if_test(MATCH_HOW_EQ_SRC(), MATCH_HOW_EQ_NAME())
    print_ind_line("break;")
    print_dec_indent()
    
    print_ind_line("case " MATCH_HOW_LT_NAME() ":")
    print_inc_indent()
    output_if_test(MATCH_HOW_LT_SRC(), MATCH_HOW_LT_NAME())
    print_ind_line("break;")
    print_dec_indent()
    
    print_ind_line("default:")
    print_inc_indent()
    print_ind_line("break;")
    print_dec_indent()
    
    print_dec_indent()
    print_ind_line("}")
    
    print_dec_indent()
    print_ind_line("}")
    print_dec_indent()
    print_ind_line("}")
    print_ind_line()

    # do not reset fname so all fnames are available for awk_END()
	#reset_fname()
	reset_input()
	reset_match_with()
	reset_match_how()
}

function init() {
	if (StdOut)
		print_set_stdout(StdOut)
	if (StdErr)
		print_set_stderr(StdErr)
	if (Help)
		print_help()
	if (Version)
		print_version()
	if (ARGC != 2)
		print_use_try()
}

function on_BEGIN() {
	init()

    print_ind_line("// machine generated file")
    
    # print headers
    print_ind_line("#include <stdio.h>")
    print_ind_line("#include <math.h>")
    print_ind_line("#include <stdlib.h>")
    print_ind_line()
    
    # print intfact()
    print_ind_line("int intfact(int n)")
    print_ind_line("{")
    print_inc_indent()
    print_ind_line("if (n < 0 || n > 12) return -1;")
    print_ind_line("if (n < 2) return 1;")
    print_ind_line("return n * intfact(n-1);")
    print_dec_indent()
    print_ind_line("}")
    print_ind_line()
    
    # print intsqrt()
    print_ind_line("int intsqrt(int n)")
    print_ind_line("{")
    print_inc_indent()
    print_ind_line("if (n < 0) return -1;")
    print_ind_line("double sqroot = sqrt(n);")
    print_ind_line("if (fabs(floor(sqroot)) == fabs(sqroot)) return sqroot;")
    print_ind_line("return -2;")
    print_dec_indent()
    print_ind_line("}")
    print_ind_line()
}

function on_END() {

    # print main()
    print_ind_line("int main(void)")
    print_ind_line("{")
    print_inc_indent()
    
    end = get_fname_count();
    for (i = 1; i <= end; ++i)
        print_ind_line("test_" get_fname(i) "();")
    
    print_ind_line("return 0;")
    print_dec_indent()
    print_ind_line("}")
}
# </user_events>
