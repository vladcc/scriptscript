!!!NOTE!!! This project is superseded by:
https://github.com/vladcc/shawk/tree/main/shawk/awk/smpg



This is an awk script which reads a list of rules and outputs a line oriented
parser. The parser makes sure the rules appear in the input (as the first field)
in the same order in which they were defined. The user is in control if what
data, if any, is associated with a rule.

The syntax for the rules is in the form of:

A -> B {| C}

where {} means zero or more

A, B, and C are rule names (any of which can be the same name), the '->' is read
as 'is followed by', and  the '|' is read as 'or' Lines beginning with a '#' are
comments and empty lines are ignored. Note that comments can only be alone on a
line, not placed after code. Rule names must start with a letter or an
underscore, followed by zero or more letters, numbers, or underscores.
The rules used to generate the parser can be found at the end of the generated
script, or displayed by -vHelp=1 User function and variable names should not
start with two underscores to avoid name clashing.

As an example:

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

With the above input, scriptscript generates a parser which recognizes files
with the following structure:

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

The rules about comments and empty lines are the same in the generated parser as
well.

The generated parser provides an event driven api, e.g. when a line starting
with 'input' is read, the on_input() function is called. A short user api is
provided for convenience.

For a full example, check the ./scriptscript/example directory. The parser there
generates the functions it tests, one of which uses math.h, so you may need to
link to standard math.
