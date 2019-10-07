What's this and why it exists?

Imagine you are writing a function which takes a number and returns a number.
You want to test it. You write a bunch of ifs where you call the function, check
the output, and print an error message if it's not what you'd expect. So far,
so good. But it turns out you later need to change the implementation and add
more tests. You decide that it'd be easier if you create an array of structs,
each struct holding an input value and a result value, and loop over it.
Wonderful improvement. However, a few days later it turns out you have to write
another function, which too requires the same method of testing, but with
different data. You are not looking forward to duplicating code just to change
a few names and some values, so you write a script which generates test code
from test data. Another improvement and a great victory. However, after a while
you write something completely different which again can be tested in a data
driven manner. However, the data is also totally different than in your previous
cases. And you are not looking forward to writing a test generation script again
just to change some names and some values again. So you write a script which
generates a script which reads test data and generates test code. That's
scriptscript.

scriptscript reads a list of rules and outputs a line oriented parser. The
parser makes sure the order of the rules is followed, and that each rule, except
the last (more on this later), has data associated with it. The syntax for
scriptscript is in the form of:

A -> B
A -> B | C

where A, B, and C are rule names, the '->' is read as 'is followed by', and  the
'|' is read as 'or' Lines beginning with a '#' are comments and empty lines are 
ignored. Note that comments can only be alone on a line, not placed after code.
Rule names must start with a letter or an underscore, followed by zero or more
letters, numbers, or underscores.

Example input may look like this:

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

With this input, scriptscript will generate a parser which recognizes files with
the following structure:

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

The same rules about comments and empty lines are valid in the generated parser.
The <something> part is your actual test data.

The parser has a function called handle_<rule-name>() for each rule,
which is called when a line starting with that rule is read. Also, there are
functions called save_<rule-name>(), get_<rule-name>_count(),get_<rule-name>(n),
and reset_<rule-name>() for each rule. They let you save the data of the rule,
get the number of rules read, get the data for rule number n, and delete all
rules of type <rule-name>, zeroing the counter, respectively. These exist for
each rule, except the last, and save_<rule-name>() is called by default in each
rule handler. The last rule is special because its purpose is to mark endpoints
between different test cases. In the example, the user can generate their test
code in handle_generate() without having to write much, if anything, else.

The generated parser provides two function called awk_BEGIN() and awk_END(),
which are called at BEGIN {} and END {} respectively. If an error has occurred
during processing, awk_END() is not executed. The user can raise an error with
input_error(error_msg), where error_msg is, unsurprisingly, the error message
string. A library for more convenient output is also provided:

print_set_indent(tabs) - Sets the default indentation to a 'tabs' number of
tabs. This indentation is printed before every string printed through the
print lib.

print_get_indent() - Returns the number of tabs currently used for default
indentation.

print_tabs(tabs,    i, end) - Prints a 'tabs' number of tabs.

print_new_lines(new_lines,    i) - Prints a 'new_lines' number of empty lines.

print_string(str, tabs) - Prints a 'tabs' number of tabs followed by the string
'str' without printing a new line after it. 'tabs' can be omitted and is then
zero.

print_line(str, tabs) - Like print_string(), but prints a new line after 'str'

You can opt to not generate the commented 'html' tags in the parser code by
calling scriptscript with '-v awk_print_tags=no'

For a full example, check the ./scriptscript/example directory. The parser there
also generates the functions it tests, one of which uses math.h, so you may need
to link to standard math.
