What's this and what does it do?

It's an awk script which reads a list of rules and outputs a line oriented
parser. The parser makes sure the order of the rules is followed, and that each
rule has data associated with it. The last rule of the input file must be the
last rule declared. Note that this is intentionally enforced by checks in the
user API, so it can be easily changed. 

The syntax for the rules is in the form of:

A -> B {| C}

where {} means zero or more

A, B, and C are rule names (any of which can be the same name), the '->' is read
as 'is followed by', and  the '|' is read as 'or' Lines beginning with a '#' are
comments and empty lines are ignored. Note that comments can only be alone on a
line, not placed after code. Rule names must start with a letter or an
underscore, followed by zero or more letters, numbers, or underscores.
The rules used to generate the parser can be found at the end of the generated
script. Function and variable names starting with two underscores are reserved.

As an example, with:

---------------------------
# fname - function name
# input - the input value for the function specified by fname
# match_with - a value to be matched with the result of calling fname(input)
# match_how - how to perform the match (==, <=, >, etc.)
# generate - generate all test cases specified for fname

fname -> input
input -> match_with
match_with -> match_how
match_how -> input | generate
generate -> fname
---------------------------

this input, scriptscript generates a parser which recognizes files with the
following structure:

---------------------------
# function name
fname <something>

# first test case
input <something>
match_with <something>
match_how <something>

# second test case
input <something>
match_with <something>
match_how <something>

# more test cases
...
generate
---------------------------

The same rules about comments and empty lines are the same in the generated
parser as well.

The generated parser has a function called handle_<rule-name>() for each rule,
which is called when a line starting with that rule is read. Also, there are
functions called save_<rule-name>(), get_<rule-name>_count(),get_<rule-name>(n),
and reset_<rule-name>() for each rule. They let you save the data of the rule,
get the number of rules read, get the data for rule number n, and delete all
rules of type <rule-name>, zeroing the counter, respectively.

Functions called awk_BEGIN() and awk_END(), which are called at BEGIN {} and
END {} are also provided. If an error has occurred during processing,
awk_END() is not executed. The user can raise an error with the in_error()
function. The following output library is also provided:

print_set_indent(tabs) - Sets the current indentation to a 'tabs' number of
tabs. This indentation is printed before every string printed through the
print lib.

print_get_indent() - Returns the number of tabs currently used for indentation.

print_inc_indent() - Does print_set_indent(print_get_indent()+1)

print_dec_indent() - Does print_set_indent(print_get_indent()-1)

print_tabs(tabs,    i, end) - Prints a 'tabs' number of tabs.

print_new_lines(new_lines,    i) - Prints a 'new_lines' number of empty lines.

print_string(str, tabs) - Prints a 'tabs' number of tabs followed by the string
'str' without printing a new line after.

print_line(str, tabs) - Like print_string(), but with a new line.

For a full example, check the ./scriptscript/example directory. The parser there
also generates the functions it tests, one of which uses math.h, so you may need
to link to standard math.
