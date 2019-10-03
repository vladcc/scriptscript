#!/usr/bin/awk -f

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

function error_two_eofs(str) {print "fileds 3 and 5 are both EOF"}
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
    else if (err_no == ERR_TWO_EOFS)
        error_two_eofs(str)
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

# match non-comments
$0 !~ /^[[:space:]]*#/ {
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

function syntax_check_5(    tmp) {
    syntax_check_3()
    syntax_match($4, BAR_RE, ERR_NO_BAR)
    syntax_match($5, WORD_RE, ERR_BAD_RULE)
    
    if ($3 == EOF_STR) {
        if ($3 == $5)
            error_set(ERR_TWO_EOFS)
        else {
            tmp = $5
            $5 = $3
            $3 = tmp
        }
    }
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

function output_get_rule_name(rule) {return "RULE_" toupper(rule)}
function output_get_handler_name(what) {return "handle_" what}

function output_emit_rule(str,    tmp) {
    tmp = output_get_handler_name(str)
    
    output_line()
    output_line("$1 == " output_get_rule_name(str) " {"\
        STATE_TRASITION_FNAME "($1); " tmp "()}")
    output_open_function(tmp)
    output_line()
    output_close_block()
}

function output_all() {
    output_line("#!/usr/bin/awk -f")
    output_line()
    output_handlers()
    output_print_lib()
    output_divide()
    output_state_machine()
    output_rules()
    output_begin()
    output_end()
}

function output_handlers(    i, end, arr) {
    output_open_tag(TAG_USER_EVENTS)

    end = input_get_line_count()
    for (i = 1; i <= end; ++i) {
        fields = split(input_get_line(i), arr)
        
        output_empty_function(output_get_handler_name(arr[1]))
        output_line()
    }
    
    output_empty_function(AWK_BEGIN)
    output_line()
    output_empty_function(AWK_END)
    
    output_close_tag(TAG_USER_EVENTS)
}

function output_print_lib() {
    PRINT_TAB = "print_tab"
    PRINT_NEW_LINE = "print_new_line"
    PRINT_STRING = "print_string"
    PRINT_LINE = "print_line"
    
    output_open_tag(TAG_PRINT_LIB)
    
    output_open_function(PRINT_TAB, "tabs,    i")
    output_line("for (i = 1; i <= tabs; ++i)", 1)
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
    output_line(PRINT_NEW_LINE "()", 1)
    output_close_block()
    output_close_tag(TAG_PRINT_LIB)
}

function output_divide(    i, end) {
    printf("#")
    end = 78
    for (i = 1; i <= end; ++i) { printf("=") }
    printf("#")
    output_line()
    
    printf("#")
    end = 24
    for (i = 1; i <= end; ++i) { printf(" ") }
    printf("machine generated parser below")
    end = 24
    for (i = 1; i <= end; ++i) { printf(" ") }
    printf("#")
    output_line()
    
    printf("#")
    end = 78
    for (i = 1; i <= end; ++i) { printf("=") }
    printf("#")
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

function is_rule_eof(rule,    i, end, fields, arr_input) {
    end = input_get_line_count()
    for (i = 1; i <= end; ++i) {
        fields = split(input_get_line(i), arr_input)
        
        if (rule == arr_input[1])
            return ((arr_input[3] == EOF_STR) || (arr_input[5] == EOF_STR))
    }
}

function output_first(arr_input,    sm_var) {
    sm_var = CURRENT_STATE_VAR
    
    output_open_if(sm_var " == \"\"", 1)
        output_open_if("next_state == " output_get_rule_name(arr_input[1]), 2)
        
            if (!is_rule_eof(arr_input[1])) {
                output_line("if (NF < 2) " NO_DATA_ERR_FNAME "(next_state)", 3)
                output_line("else " sm_var " = next_state", 3)
            }
            else
                output_line(sm_var " = next_state", 3)
        output_close_block(2)
        output_line("else " PARSE_ERR_FNAME\
            "(" output_get_rule_name(arr_input[1]) ", next_state)", 2)
    output_close_block(1)
}

function output_three(arr_input,    sm_var) {
    sm_var = CURRENT_STATE_VAR
    
    output_open_else_if(sm_var " == " output_get_rule_name(arr_input[1]), 1)
        
    if (arr_input[3] == EOF_STR) {
        output_line(sm_var " = \"\"", 3)
        output_close_block(2)
    }
    else {
        output_open_if("next_state == "\
            output_get_rule_name(arr_input[3]), 2)
            if (!is_rule_eof(arr_input[3])) {
                output_line("if (NF < 2) " NO_DATA_ERR_FNAME "(next_state)", 3)
                output_line("else " sm_var " = next_state", 3)
            }
            else
               output_line(sm_var " = next_state", 3)
        output_close_block(2)
    }
}

function output_end_three(arr_input) {
    output_line("else " PARSE_ERR_FNAME\
        "(" output_get_rule_name(arr_input[3]) ", next_state)", 2)
}

function output_five(arr_input,    sm_var, tmp) {
    sm_var = CURRENT_STATE_VAR

   output_three(arr_input)
    
    if (arr_input[5] != EOF_STR) {
        output_open_else_if("next_state == "\
            output_get_rule_name(arr_input[5]), 2)
            
            if (!is_rule_eof(arr_input[5])) {
                output_line("if (NF < 2) " NO_DATA_ERR_FNAME "(next_state)", 3)
                output_line("else " sm_var " = next_state", 3)
            }
            else
                output_line(sm_var " = next_state", 3)

        output_close_block(2)
    }
}

function output_end_five(arr_input) {
    output_string("else " PARSE_ERR_FNAME "(", 2)
    output_string(output_get_rule_name(arr_input[3]))
    
    if (arr_input[5] != EOF_STR)
        output_string(" \"' or '\" " output_get_rule_name(arr_input[5]))
    output_line(", next_state)")
}

function output_state_machine(    i, lines, fields, sm_var, arr_input) {    
    sm_var = CURRENT_STATE_VAR
    
    output_open_tag(TAG_STATE_MACHINE)
    output_error_raise()
    output_parse_error()
    output_no_data_error()
    output_open_function(STATE_TRASITION_FNAME, "next_state")
    
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
            STATE_TRASITION_FNAME "($1); "\
            output_get_handler_name(arr[1]) "(); next}")
    }
    output_line("$0 ~ /^$/ {next} # ignore empty lines")
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

function output_end() {
    output_open_tag(TAG_END)
    output_line("END {")
    output_open_if("!" GLOBAL_ERR_FLAG, 1)
        output_line("if (" CURRENT_STATE_VAR " != "\
            output_get_rule_name(ACCEPT_STATE) ")", 2)
            output_line(ERROR_RAISE_FNAME "(NR,\\", 3)
            output_line("\"file should end with '\" "\
                    output_get_rule_name(ACCEPT_STATE) " \"'\")", 4)
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
    AWK_BEGIN = "awk_BEGIN"
    AWK_END = "awk_END"
    
    STATE_TRASITION_FNAME = "state_transition"
    PARSE_ERR_FNAME = "parse_error"
    NO_DATA_ERR_FNAME = "no_data_error"
    ERROR_RAISE_FNAME = "error_raise"
    GLOBAL_ERR_FLAG = "__error_happened__"
    CURRENT_STATE_VAR = "__sm_now__"
    ACCEPT_STATE = ""
    
    ERR_BAD_NF = 0
    ERR_NO_ARROW = 1
    ERR_NO_BAR = 2
    ERR_BAD_RULE = 3
    ERR_TWO_EOFS = 4
    
    YES = "yes"
    NO = "no"
    EOF_STR = "EOF"
    start_set_awk_print_tags()
}
# </start>
