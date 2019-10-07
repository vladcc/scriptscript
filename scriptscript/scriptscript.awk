#!/usr/bin/awk -f

# scriptscript.awk -- a test case parser generator
# v1.0
# Author: Vladimir Dinev
# vld.dinev@gmail.com
# 2019-10-06

# <error handling>
function error_print_header() {print ERROR "line " NR ": '" $0 "'"}
function error_print_expected(wanted, got) {
    print "'" wanted "' expected but got '" got "' instead"
}

function error_no_arrow(str) {error_print_expected(ARROW_STR, $2)}
function error_no_bar(str) {error_print_expected(BAR_STR, $4)}
function error_bad_nf(str) {
    print "wrong number of fields"
    print "allowed syntax is:"
    print "A -> B"
    print "or"
    print "A -> B | C"
}

function error_bad_rule(rule, str) {
    print "rule '" rule "' must start with a letter or an underscore"
    print "and contain only letters, numbers, and underscores"
}

function error_raise() {g_error_happened = 1}
function error_happened() {return g_error_happened}
function error_set(err_no, str) {
    error_print_header()
    
    if (err_no == ERR_BAD_FIELD_NUM)
        error_bad_nf(str)
    else if (err_no == ERR_NO_ARROW)
        error_no_arrow(str)
    else if (err_no == ERR_NO_BAR)
        error_no_bar(str)
    else if (err_no == ERR_BAD_RULE)
        error_bad_rule(str)
    else
        print "Unknown error: '" err_no "'"
    
    error_raise()
}
# </error handling>

# <input>
function input_inc_line_count() {++g_line_count}
function input_get_line_count() {return g_line_count}
function input_get_line(n) {return g_all_lines[n]}
function input_save_line(line) {
    input_inc_line_count() 
    g_all_lines[input_get_line_count()] = line
}

$0 ~ /^[[:space:]]*$/ {next}
$0 ~ /^[[:space:]]*#/ {next}

# match non-comments
{
    if (syntax_check_line()) {
        ACCEPT_STATE = $1
        input_save_line($0)
    }
}
# </input>

# <syntax>
function syntax_check_line() {
# allowed only
# A -> B
# or
# A -> B | C

    if (NF == 3)
        syntax_check_3()
    else if (NF == 5)
        syntax_check_5()
    else
        error_set(ERR_BAD_NF)
    
    return !error_happened()
}

function syntax_check_3() {
    syntax_match($1, WORD_RE, ERR_BAD_RULE)
    syntax_match($2, ARROW_RE, ERR_NO_ARROW)
    syntax_match($3, WORD_RE, ERR_BAD_RULE)
}

function syntax_check_5() {
    syntax_check_3()
    syntax_match($4, BAR_RE, ERR_NO_BAR)
    syntax_match($5, WORD_RE, ERR_BAD_RULE)
}

function syntax_match(str, regexp, error) {
    if (str !~ regexp)
        error_set(error, str)
}
# </syntax>

# <output>
function output_tabs(n,    i) {
    for (i = 0; i < n; ++i)
        printf("\t")
}

function output_string(str, tabs) {
    output_tabs(tabs)
    printf(str)
}

function output_line(str, tabs) {
    output_tabs(tabs)
    print str
}

function output_open_function(name, params) {
    output_line("function " name "(" params ") {")
}

function output_empty_function(name, params) {
    output_open_function(name, params)
    output_line()
    output_close_block()
}

function output_open_if(condition, tabs) {
    output_line("if (" condition ") {", tabs)
}

function output_open_else_if(condition, tabs) {
    output_line("else if (" condition ") {", tabs)
}

function output_open_else(tabs) {
    output_line("else {", tabs)
}

function output_close_block(tabs) {
    output_line("}", tabs)
}

function output_open_tag(what) {
    if (start_should_print_tags())
        output_line("# <" what ">")
}
function output_close_tag(what) {
    if (start_should_print_tags())
        output_line("# </" what ">\n")
}

function output_get_rule_name(rule) {return "__RULE_" toupper(rule) "__"}
function output_get_handler_name(what) {return "handle_" what}

function output_emit_rule(str,    tmp) {
    tmp = output_get_handler_name(str)
    
    output_line()
    output_line("$1 == " output_get_rule_name(str) " {"\
        STATE_TRANSITION_FNAME "($1); " tmp "()}")
    output_open_function(tmp)
    output_line()
    output_close_block()
}

function output_all() {
    output_line("#!/usr/bin/awk -f")
    output_line()
    output_handlers()
    output_print_lib()
    output_utils()
    output_divide()
    output_state_machine()
    output_rules()
    output_begin()
    output_end()
}

function output_handlers(    i, end, arr, j, jend, tmp_arr) {
    output_open_tag(TAG_USER_EVENTS)

    end = input_get_line_count()
    for (i = 1; i <= end; ++i) {
        fields = split(input_get_line(i), arr)
        
        if (!is_last_rule(arr[1])) {
            output_open_function(output_get_handler_name(arr[1]))
            output_line("save_" arr[1] "($2)", 1)
            output_close_block()
            tmp_arr[++jend] = arr[1]
        }
        else {
            output_open_function(output_get_handler_name(arr[1]))
            output_line()
            output_line()
            for (j = 1; j <= jend; ++j)
                output_line("reset_" tmp_arr[j] "()", 1)
            output_close_block()
        }
        
        output_line()
    }
    
    output_empty_function(AWK_BEGIN)
    output_line()
    output_empty_function(AWK_END)
    output_line()
    
    INPUT_ERROR_USR = "input_error"
    output_open_function(INPUT_ERROR_USR, "error_msg")
    output_line(ERROR_RAISE_FNAME "(NR, error_msg)", 1)
    output_close_block()
    
    output_close_tag(TAG_USER_EVENTS)
}

function output_print_lib() {
    PRINT_BASE_INDENT = "__base_indent__"
    PRINT_SET_INDENT = "print_set_indent"
    PRINT_GET_INDENT = "print_get_indent"
    PRINT_TAB = "print_tabs"
    PRINT_NEW_LINE = "print_new_lines"
    PRINT_STRING = "print_string"
    PRINT_LINE = "print_line"
    
    output_open_tag(TAG_PRINT_LIB)
    
    output_open_function(PRINT_SET_INDENT, "tabs")
    output_line(PRINT_BASE_INDENT " = tabs", 1)
    output_close_block()
    output_line()
    
    output_open_function(PRINT_GET_INDENT)
    output_line("return " PRINT_BASE_INDENT, 1)
    output_close_block()
    output_line()
    
    output_open_function(PRINT_TAB, "tabs,    i, end")
    output_line("end = tabs + " PRINT_GET_INDENT "()", 1)
    output_line("for (i = 1; i <= end; ++i)", 1)
    output_line("printf(\"\\t\")", 2)
    output_close_block()
    output_line()

    output_open_function(PRINT_NEW_LINE, "new_lines,    i")
    output_line("for (i = 1; i <= new_lines; ++i)", 1)
    output_line("printf(\"\\n\")", 2)
    output_close_block()
    output_line()
    
    output_open_function(PRINT_STRING, "str, tabs")
    output_line(PRINT_TAB "(tabs)", 1)
    output_line("printf(str)", 1)
    output_close_block()
    output_line()
    
    output_open_function(PRINT_LINE, "str, tabs")
    output_line(PRINT_STRING "(str, tabs)", 1)
    output_line(PRINT_NEW_LINE "(1)", 1)
    output_close_block()
    output_close_tag(TAG_PRINT_LIB)
}

function output_utils(    i, end, fields, arr_input, tmp, tmp_arr, tmp_num) {
    end = input_get_line_count()
    
    output_open_tag(TAG_UTILS)
    
    for (i = 1; i <= end; ++i) {
        fields = split(input_get_line(i), arr_input)
        tmp = arr_input[1]
        
        if (!is_last_rule(tmp)) {
            tmp_arr = "__" tmp "_arr__"
            tmp_num = "__" tmp "_num__"
            
            output_string("function save_" tmp "(" tmp ") {")
            output_line(tmp_arr "[++" tmp_num "] = " tmp "}")
            
            output_string("function get_" tmp "_count() {")
            output_line("return " tmp_num "}")
            
            output_string("function get_" tmp "(num) {")
            output_line("return " tmp_arr "[num]}")
            
            output_string("function reset_" tmp "() {")
            output_line("delete " tmp_arr "; " tmp_num " = 0}")
        
            if (i < end-1)
                output_line()
        }
        
    }
    
    output_close_tag(TAG_UTILS)
}

function output_divide(    i, end) {
    output_string("#")
    end = 78
    for (i = 1; i <= end; ++i) { output_string("=") }
    output_string("#")
    output_line()
    
    output_string("#")
    end = 24
    for (i = 1; i <= end; ++i) { output_string(" ") }
    output_string("machine generated parser below")
    end = 24
    for (i = 1; i <= end; ++i) { output_string(" ") }
    output_string("#")
    output_line()
    
    output_string("#")
    end = 78
    for (i = 1; i <= end; ++i) { output_string("=") }
    output_string("#")
    output_line()
    output_line()
}

function output_error_raise() {
    output_open_function(ERROR_RAISE_FNAME, "line_no, error_msg")
    output_line("print \"error: line \" line_no \": \" error_msg", 1)
    output_line(GLOBAL_ERR_FLAG " = 1", 1)
    output_line("exit(1)", 1)
    output_close_block()
}

function output_parse_error() {
    output_open_function(PARSE_ERR_FNAME, "expected, got")
    output_line(ERROR_RAISE_FNAME "(NR, "\
    "\"'\" expected \"' expected, but got '\" got \"' instead\")", 1)
    output_close_block()
}

function output_no_data_error() {
    output_open_function(NO_DATA_ERR_FNAME, "what")
    output_line(ERROR_RAISE_FNAME "(NR, \"no data after '\" what \"'\")", 1)
    output_close_block()
}

function is_last_rule(rule) {
    return rule == ACCEPT_STATE
}

function output_data_check(rule, tabs,    sm_var, ret) {
    sm_var = CURRENT_STATE_VAR
    ret = (rule != ACCEPT_STATE)
    
    if (ret) {
        output_line("if (NF < 2) " NO_DATA_ERR_FNAME "(next_state)", tabs)
        output_line("else " sm_var " = next_state", tabs)
    }
    
    return ret
}

function output_first(arr_input,    sm_var, tmp) {
    sm_var = CURRENT_STATE_VAR
    
    output_open_if(sm_var " == \"\"", 1)
        
        tmp = output_get_rule_name(arr_input[1])
        output_open_if("next_state == " tmp, 2)
            if (!output_data_check(arr_input[1], 3)) 
                output_line(sm_var " = next_state", 3)
        output_close_block(2)
        output_line("else " PARSE_ERR_FNAME "(" tmp ", next_state)", 2)
        
    output_close_block(1)
}

function output_three(arr_input,    sm_var, tmp) {
    sm_var = CURRENT_STATE_VAR
    
    tmp = output_get_rule_name(arr_input[1])
    output_open_else_if(sm_var " == " tmp, 1)
        
    tmp = output_get_rule_name(arr_input[3])
    output_open_if("next_state == " tmp, 2)
        if (!output_data_check(arr_input[3], 3)) 
           output_line(sm_var " = next_state", 3)
    output_close_block(2)
}

function output_end_three(arr_input,    tmp) {
    tmp = output_get_rule_name(arr_input[3])
    output_line("else " PARSE_ERR_FNAME "(" tmp ", next_state)", 2)
}

function output_five(arr_input,    sm_var, tmp) {
    sm_var = CURRENT_STATE_VAR

    output_three(arr_input)
    tmp = output_get_rule_name(arr_input[5])
    output_open_else_if("next_state == " tmp, 2)
        
        if (!output_data_check(arr_input[5], 3)) 
            output_line(sm_var " = next_state", 3)
            
    output_close_block(2)
}

function output_end_five(arr_input) {
    output_string("else " PARSE_ERR_FNAME "(", 2)
    output_string(output_get_rule_name(arr_input[3]))s
    output_string(" \"' or '\" " output_get_rule_name(arr_input[5]))
    output_line(", next_state)")
}

function output_state_machine(    i, lines, fields, sm_var, arr_input) {    
    sm_var = CURRENT_STATE_VAR
    
    output_open_tag(TAG_STATE_MACHINE)
    output_error_raise()
    output_parse_error()
    output_no_data_error()
    output_open_function(STATE_TRANSITION_FNAME, "next_state")
    
    fields = split(input_get_line(1), arr_input)
    output_first(arr_input)
    
    lines = input_get_line_count()
    for (i = 1; i <= lines; ++i) {
        fields = split(input_get_line(i), arr_input)
        
        if (fields == 3) {
            output_three(arr_input)
            output_end_three(arr_input)
        }
        else if (fields == 5) {
            output_five(arr_input)
            output_end_five(arr_input)
        }
        
        output_close_block(1)
    }
    
    output_close_block(0)
    output_close_tag(TAG_STATE_MACHINE)
}

function output_rules(    i, end, arr, fields) {
    output_open_tag(TAG_INPUT)
    printf("$0 ~ /^[[:space:]]*#/ {next} # match comments\n")
    
    end = input_get_line_count()
    for (i = 1; i <= end; ++i) {
        fields = split(input_get_line(i), arr)
        output_line("$1 ~ " output_get_rule_name(arr[1]) " {"\
            STATE_TRANSITION_FNAME "($1); "\
            output_get_handler_name(arr[1]) "(); next}")
    }
    
    output_line("$0 ~ /^[[:space:]]*$/ {next} # ignore empty lines")
    output_line("{" ERROR_RAISE_FNAME "(NR, \"'\" $1 \"' unknown\")}")
    output_close_tag(TAG_INPUT)
}

function output_begin(    i, end, arr) {
    end = input_get_line_count()
    
    output_open_tag(TAG_START)
    output_line("BEGIN {")
    for (i = 1; i <= end; ++i) {
        split(input_get_line(i), arr)
        output_line(output_get_rule_name(arr[1]) " = \"" arr[1] "\"", 1)
    }
    
    output_line(GLOBAL_ERR_FLAG " = 0", 1)
    output_line(AWK_BEGIN "()", 1)
    output_close_block()
    output_close_tag(TAG_START)
}

function output_end(    tmp) {
    output_open_tag(TAG_END)
    output_line("END {")
    output_open_if("!" GLOBAL_ERR_FLAG, 1)
        
        tmp = output_get_rule_name(ACCEPT_STATE)
        output_line("if (" CURRENT_STATE_VAR " != " tmp ")", 2)
            output_line(ERROR_RAISE_FNAME\
                "(NR, \"file should end with '\" " tmp " \"'\")", 3)
            output_line("else",2)
                output_line( AWK_END "()", 3)
        output_close_block(1)
    output_close_block()
    output_close_tag(TAG_END)
}
# </output>

# <finish>
END {
    if (error_happened()) 
        exit(1)
    else
        output_all()
}
# </finish>

# <start>
function start_should_print_tags() {return awk_print_tags == YES}
function start_set_awk_print_tags() {
    if (awk_print_tags == "")
        awk_print_tags = YES

    if (awk_print_tags != YES && awk_print_tags != NO) {
        print ERROR "unknown value '" awk_print_tags "'"
        print "syntax: -v awk_print_tags=<\"" YES "\"/\"" NO "\">"
        error_raise()
        exit(1)
    }
}

BEGIN {
    WORD_RE = "^[[:alpha:]_][[:alnum:]_]*$"
    ARROW_RE = "^->$"
    ARROW_STR = "->"
    BAR_RE = "^\\|$"
    BAR_STR = "->"
    ERROR = "error: "
    TAG_START = "start"
    TAG_INPUT = "input"
    TAG_END = "end"
    TAG_STATE_MACHINE = "state_machine"
    TAG_USER_EVENTS = "user_events"
    TAG_PRINT_LIB = "print_lib"
    TAG_UTILS = "utils"
    AWK_BEGIN = "awk_BEGIN"
    AWK_END = "awk_END"
    
    STATE_TRANSITION_FNAME = "__state_transition"
    PARSE_ERR_FNAME = "__parse_error"
    NO_DATA_ERR_FNAME = "__no_data_error"
    ERROR_RAISE_FNAME = "__error_raise"
    GLOBAL_ERR_FLAG = "__error_happened__"
    CURRENT_STATE_VAR = "__sm_now__"
    ACCEPT_STATE = ""
    
    ERR_BAD_NF = 0
    ERR_NO_ARROW = 1
    ERR_NO_BAR = 2
    ERR_BAD_RULE = 3
    
    YES = "yes"
    NO = "no"
    start_set_awk_print_tags()
}
# </start>