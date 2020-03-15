#!/usr/bin/awk -f

# scriptscript.awk -- a code generator parser generator
# for version look at the VERSION variable
# Author: Vladimir Dinev
# vld.dinev@gmail.com
# 2020-03-15

# <error_handling>
function error_raise() {LG_err_happened = 1}
function error_happened() {return LG_err_happened}
function error(str, line_no) {
    error_raise()
    printf("error: %s, line %d : %s\n",
        FILENAME, (line_no) ? line_no : FNR, str)
    exit(1)
}
# </error_handling>

# <input>
function in_get_num_rules() {return LO_next_rule}
function in_next_rule() {return ++LO_next_rule}
function in_get_rule_name(n) {return LO_rules[n]}
function in_get_rule_line(rule) {return LO_rules[rule, RL_LINE]}
function in_get_rule_flw_num(rule) {return LO_rules[rule, RL_MEM_FLW_NUM]}
function in_get_rule_flw(rule, n) {return LO_rules[rule, RL_MEM_FOLLOW n]}

function rule_set_accept(rule) {LG_accept = rule}
function rule_get_accept() {return LG_accept}
function rule_is_accept(rule) {return LG_accept == rule}

function rule_is_defined(rule,    i, end) {
    end = in_get_num_rules()
    for (i = 1; i <= end; ++i) {
        if (rule == in_get_rule_name(i))
            return 1
    }
    return 0
}

function in_save_line() {LO_lines[in_next_line()] = $0}
function in_next_line() {return ++LO_next_line}
function in_get_line_num() {return LO_next_line}
function in_get_line(n) {return LO_lines[n]}

function in_save(row,    rule, rest, tmp_arr, tmp_var, i) {
    # remember original source line
    in_save_line()
    
    # remove spaces
    gsub(/[[:space:]]+/, "", row)

    # split rule from rest
    if (split(row, tmp_arr, RL_ARROW) != 2)
        error(sprintf("bad '%s' syntax", RL_ARROW))

    rule = tmp_arr[1]
    rest = tmp_arr[2]
    
    if (!rest)
        error(sprintf("no follow up after rule '%s'", rule))
    
    # check rule syntax
    if (!match(rule, RL_REGX))
        error(sprintf("'%s' not a valid rule syntax", rule))
    
    if (rule_is_defined(rule))
        error(sprintf("'%s' rule redefined", rule))
        
    # save rule
    LO_rules[in_next_rule()] = rule
    
    # save rule line for later error messages
    LO_rules[rule, RL_LINE] = FNR
    
    # split rule follow ups
    tmp_var = split(rest, tmp_arr, RL_BAR)
    
    for (i = 1; i <= tmp_var; ++i) {
        if (match(tmp_arr[i], RL_REGX))
            LO_rules[rule, RL_MEM_FOLLOW i] = tmp_arr[i]
        else
            error(sprintf("follow up number %d '%s' syntax not valid",
                i, tmp_arr[i]))
    }
    
    LO_rules[rule, RL_MEM_FLW_NUM] = tmp_var
    rule_set_accept(rule)
}

$0 ~ /^[[:space:]]*$/ {next} # empty lines
$0 ~ /^[[:space:]]*#/ {next} # comments
{in_save($0)} # non-comments
# </input>

# <output>
function out_tabs(n,    i) {for (i = 0; i < n; ++i) printf("\t")}
function out_string(str, tabs) {out_tabs(tabs); printf(str)}
function out_line(str, tabs) {out_tabs(tabs); print str}
function out_open_else(tabs) {out_line("else {", tabs)}
function out_close_block(tabs) {out_line("}", tabs)}
function out_open_tag(what) {out_line(sprintf("# <%s>", what))}
function out_close_tag(what) {out_line(sprintf("# </%s>\n", what))}
function out_get_rule_name(rule) {return "__R_" toupper(rule)}
function out_get_handler_name(what) {return "handle_" what}

function out_open_function(name, params) {
    out_line(sprintf("function %s(%s) {", name, params))
}

function out_empty_function(name, params) {
    out_open_function(name, params)
    out_line()
    out_close_block()
}

function out_open_if(condition, tabs) {
    out_line(sprintf("if (%s) {", condition), tabs)
}

function out_open_else_if(condition, tabs) {
    out_line(sprintf("else if (%s) {", condition), tabs)
}

function out_all() {
    out_line("#!/usr/bin/awk -f\n")
    out_handlers()
    out_print_lib()
    out_utils()
    out_divide()
    out_state_machine()
    out_rules()
    out_begin()
    out_end()
    out_source()
    out_line(sprintf("# generated by %s %s", PROG_NAME, VERSION))
}

function out_handlers(    rule, i, end, j, jend, tmp_arr) {
    out_open_tag(TAG_USER_EVENTS)
    end = in_get_num_rules()
    for (i = 1; i <= end; ++i) {
        rule = in_get_rule_name(i)
        
        out_open_function(out_get_handler_name(rule))
        
        if (!rule_is_accept(rule)) {
            out_line(sprintf("save_%s($2)", rule), 1)
            tmp_arr[++jend] = rule
        } else {
            out_line()
            out_line()
            for (j = 1; j <= jend; ++j)
                out_line(sprintf("reset_%s()", tmp_arr[j]), 1)
        }
        out_close_block()
        out_line()
    }
    
    out_empty_function(AWK_BEGIN)
    out_line()
    out_empty_function(AWK_END)
    out_line()
    
    out_open_function("in_error", "error_msg")
    out_line(ERROR_RAISE_FNAME "(error_msg)", 1)
    out_close_block()
    out_close_tag(TAG_USER_EVENTS)
}

function out_print_lib() {
    PRINT_BASE_INDENT = "__base_indent__"
    PRINT_SET_INDENT = "print_set_indent"
    PRINT_GET_INDENT = "print_get_indent"
    PRINT_INC_INDENT = "print_inc_indent"
    PRINT_DEC_INDENT = "print_dec_indent"
    PRINT_TAB = "print_tabs"
    PRINT_NEW_LINE = "print_new_lines"
    PRINT_STRING = "print_string"
    PRINT_LINE = "print_line"
    FUNCT = "function"
    
    out_open_tag(TAG_PRINT_LIB)
    out_line(sprintf("%s %s(tabs) {%s = tabs}",
        FUNCT, PRINT_SET_INDENT, PRINT_BASE_INDENT))
        
    out_line(sprintf("%s %s() {return %s}",
        FUNCT, PRINT_GET_INDENT, PRINT_BASE_INDENT))
    
    out_line(sprintf("%s %s() {%s(%s()+1)}",
        FUNCT, PRINT_INC_INDENT, PRINT_SET_INDENT, PRINT_GET_INDENT))
    
    out_line(sprintf("%s %s() {%s(%s()-1)}",
        FUNCT, PRINT_DEC_INDENT, PRINT_SET_INDENT, PRINT_GET_INDENT))
    
    out_line(sprintf("%s %s(str, tabs) {%s(tabs); printf(str)}",
        FUNCT, PRINT_STRING, PRINT_TAB))
    
    out_line(sprintf("%s %s(str, tabs) {%s(str, tabs); %s(1)}",
        FUNCT, PRINT_LINE, PRINT_STRING, PRINT_NEW_LINE))
    
    out_open_function(PRINT_TAB, "tabs,    i, end")
    out_line("end = tabs + " PRINT_GET_INDENT "()", 1)
    out_line("for (i = 1; i <= end; ++i)", 1)
    out_line("printf(\"\\t\")", 2)
    out_close_block()
    
    out_open_function(PRINT_NEW_LINE, "new_lines,    i")
    out_line("for (i = 1; i <= new_lines; ++i)", 1)
    out_line("printf(\"\\n\")", 2)
    out_close_block()
    out_close_tag(TAG_PRINT_LIB)
}

function out_utils(    i, end, arr_input, tmp, tmp_arr, tmp_num) {
    out_open_tag(TAG_UTILS)
    end = in_get_num_rules()
    for (i = 1; i <= end; ++i) {
        tmp = in_get_rule_name(i)
        
        if (!rule_is_accept(tmp)) {
            tmp_arr = "__" tmp "_arr__"
            tmp_num = "__" tmp "_num__"
            
            out_string("function save_" tmp "(" tmp ") {")
            out_line(tmp_arr "[++" tmp_num "] = " tmp "}")
            
            out_string("function get_" tmp "_count() {")
            out_line("return " tmp_num "}")
            
            out_string("function get_" tmp "(num) {")
            out_line("return " tmp_arr "[num]}")
            
            out_string("function reset_" tmp "() {")
            out_line("delete " tmp_arr "; " tmp_num " = 0}")
        
            if (i < end-1) out_line()
        }
    }
    out_close_tag(TAG_UTILS)
}

function out_divide(    i, end) {
    out_string("#")
    end = 78
    for (i = 1; i <= end; ++i) { out_string("=") }
    out_string("#\n")
    
    out_string("#")
    end = 24
    for (i = 1; i <= end; ++i) { out_string(" ") }
    out_string("machine generated parser below")
    for (i = 1; i <= end; ++i) { out_string(" ") }
    out_string("#\n")
    
    out_string("#")
    end = 78
    for (i = 1; i <= end; ++i) { out_string("=") }
    out_string("#\n\n")
}

function out_error_raise() {
    out_open_function(ERROR_RAISE_FNAME, "error_msg")
    out_line("printf(\"error: %s, line %d: %s\\n\",\
        FILENAME, FNR, error_msg)", 1)
    out_line(GLOBAL_ERR_FLAG " = 1", 1)
    out_line("exit(1)", 1)
    out_close_block()
}

function out_parse_error() {
    out_open_function(PARSE_ERR_FNAME, "expct, got")
    out_line(ERROR_RAISE_FNAME\
        "(sprintf(\"'%s' expected, but got '%s' instead\", expct, got))", 1)
    out_close_block()
}

function out_switch() {
    out_open_function(SWITCH_FNAME, NEXT_STATE)
        out_line(sprintf("%s = %s", CURRENT_STATE_VAR_NAME, NEXT_STATE), 1)
    out_close_block()
}

function out_check_switch() {
    out_open_function(CHECK_SWITCH_FNAME, NEXT_STATE)
        out_line(sprintf("if (NF < 2) %s(%s, %s))",
            ERROR_RAISE_FNAME,
            "sprintf(\"no data after '%s'\"",
            NEXT_STATE), 1)
        out_string("else ", 1)
        out_state_change()
    out_close_block()
}

function out_state_change(tabs) {
    out_line(sprintf("%s(%s)", SWITCH_FNAME, NEXT_STATE), tabs)
}

function out_data_check(rule, tabs,    ret) {
    if (ret = !rule_is_accept(rule))
        out_line(sprintf("%s(%s)", CHECK_SWITCH_FNAME, NEXT_STATE), tabs)
    return ret
}

function out_first(    first_rule, tmp) {
    out_open_if(sprintf("%s == \"\"", CURRENT_STATE_VAR_NAME), 1)
    
        first_rule = in_get_rule_name(1)
        tmp = out_get_rule_name(first_rule)
        
        out_string(sprintf("if (%s == %s) ", NEXT_STATE, tmp), 2)
            if (!out_data_check(first_rule))
                out_state_change()
        out_line(sprintf("else %s(%s, %s)", PARSE_ERR_FNAME, tmp, NEXT_STATE),
            2)
        
    out_close_block(1)
}

function out_next(rule,    i, end, tmp, tmp2, tmp3, err_str) {
    tmp = out_get_rule_name(rule)
    out_open_else_if(sprintf("%s == %s", CURRENT_STATE_VAR_NAME, tmp), 1)
        
        err_str = ""
        end = in_get_rule_flw_num(rule)
        for (i = 1; i <= end; ++i) {
            tmp = in_get_rule_flw(rule, i)
            tmp2 = out_get_rule_name(tmp)
            
                tmp3 = (i == 1) ? "if (%s == %s) " : "else if (%s == %s) "
                out_string(sprintf(tmp3, NEXT_STATE, tmp2), 2)
                
                    if (!out_data_check(tmp))
                        out_state_change()
                        
            err_str = (!err_str) ? tmp2 : err_str "\"|\"" tmp2
        }
        
        out_line(\
            sprintf("else %s(%s, %s)", PARSE_ERR_FNAME, err_str, NEXT_STATE), 2)
    out_close_block(1)
}

function out_state_machine(    i, end) {    
    out_open_tag(TAG_STATE_MACHINE)
    out_error_raise()
    out_parse_error()
    out_switch()
    out_check_switch()
    out_open_function(STATE_TRANSITION_FNAME, NEXT_STATE)
    
    out_first()
    
    end = in_get_num_rules()
    for (i = 1; i <= end; ++i)
        out_next(in_get_rule_name(i))

    out_close_block(0)
    out_close_tag(TAG_STATE_MACHINE)
}

function out_rules(    i, end, tmp) {
    out_open_tag(TAG_INPUT)
    end = in_get_num_rules()
    for (i = 1; i <= end; ++i) {
        tmp = in_get_rule_name(i)
        out_line("$1 == " out_get_rule_name(tmp) " {"\
            STATE_TRANSITION_FNAME "($1); "\
            out_get_handler_name(tmp) "(); next}")
    }
    
    out_line("$0 ~ /^[[:space:]]*$/ {next} # ignore empty lines")
    out_line("$0 ~ /^[[:space:]]*#/ {next} # ignore comments")
    out_line(sprintf("{%s(\"'\" $1 \"' unknown\")} # all else is error",
        ERROR_RAISE_FNAME))
    out_close_tag(TAG_INPUT)
}

function out_begin(    i, end, tmp) {
    end = in_get_num_rules()
    
    out_open_tag(TAG_START)
    out_line("BEGIN {")
    for (i = 1; i <= end; ++i) {
        tmp = in_get_rule_name(i)
        out_line(out_get_rule_name(tmp) " = \"" tmp "\"", 1)
    }
    
    out_line(GLOBAL_ERR_FLAG " = 0", 1)
    out_line(AWK_BEGIN "()", 1)
    out_close_block()
    out_close_tag(TAG_START)
}

function out_end(    tmp) {
    out_open_tag(TAG_END)
    out_line("END {")
    out_open_if("!" GLOBAL_ERR_FLAG, 1)
        
        tmp = out_get_rule_name(rule_get_accept())
        
        out_line(sprintf("if (%s != %s)", CURRENT_STATE_VAR_NAME, tmp), 2)
            out_line(sprintf("%s(%s)",
                ERROR_RAISE_FNAME,
                "sprintf(\"file should end with '%s'\", " tmp ")"), 3)
        out_line("else",2)
                out_line( AWK_END "()", 3)
        out_close_block(1)
    out_close_block()
    out_close_tag(TAG_END)
}

function out_source(    i, end) {
    out_open_tag(TAG_USER_SOURCE)
    end = in_get_line_num()
    for (i = 1; i <= end; ++i)
        out_line(sprintf("# %s", in_get_line(i)))
    out_close_tag(TAG_USER_SOURCE)
}
# </output>

# <start>
BEGIN {    
    RL_ARROW = "->"
    RL_BAR = "|"
    RL_REGX = "^[_[:alpha:]][_[:alnum:]]*$"
    RL_MEM_FOLLOW = "follow"
    RL_MEM_FLW_NUM = "num_of_follows"
    RL_LINE = "line"
    
    TAG_START = "start"
    TAG_INPUT = "input"
    TAG_END = "end"
    TAG_STATE_MACHINE = "state_machine"
    TAG_USER_EVENTS = "user_events"
    TAG_PRINT_LIB = "print_lib"
    TAG_UTILS = "utils"
    TAG_USER_SOURCE = "user_source"
    AWK_BEGIN = "awk_BEGIN"
    AWK_END = "awk_END"
    
    NEXT_STATE = "__next"
    CURRENT_STATE_VAR_NAME = "__state"
    STATE_TRANSITION_FNAME = "__state_transition"
    GLOBAL_ERR_FLAG = "__error_happened"
    PARSE_ERR_FNAME = "__parse_error"
    CHECK_SWITCH_FNAME = "__check_switch"
    SWITCH_FNAME = "__switch"
    ERROR_RAISE_FNAME = "__error_raise"
    
    PROG_NAME = "scriptscript"
    VERSION = "v2.01"
}
# </start>

# <end>
function check_all_flw_defined(    i, end, j, jend, rule, flw) {
    end = in_get_num_rules()
    for (i = 1; i <= end; ++i) {
        rule = in_get_rule_name(i)
        jend = in_get_rule_flw_num(rule)
        for (j = 1; j <= jend; ++j) {
            flw = in_get_rule_flw(rule, j)
            if (!rule_is_defined(flw))
                error(sprintf("'%s' rule undefined", flw),
                    in_get_rule_line(rule))
        }
    }
}

END {
    if (!error_happened()) {
        check_all_flw_defined()
        out_all()
    }
}
# </end>
