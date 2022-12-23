# Glue Docs

## A note on mutability

Data in Glue is **immutable**.
This means that once defined, it is that way forever.
<br />
There are ways to work around it, but are not recommended.

## What is "processed" and "unprocessed" data?

In these docs you'll hear that data is sometimes "processed", and sometimes "unprocessed". Unprocessed data means that its just your code, in its pure form. Processed data means its the result of your evaluated code.

## A note on functions

The functions defined in Glue code receive arguments that are automatically processed. However, external functions get unprocessed data, thus functions defined by Glue itself and not by your Glue code might use unprocessed arguments as if they were macros. Some functions only process SOME functions.

## A note on macros

Macros don't have named arguments. They have a local variable called `@args`, which stores a list of the converted AST of its arguments. It also must return an AST (later we will cover the expected format)

# The building blocks

Here are the building blocks that compose a Glue program:

```lisp
; A comment
null ; Null.
1.23 ; A number.
true ; A boolean (there is also false).
"text" ; A string
`[0-9]` ; A RegEx
{"key" "value" "other key" "other value"} ; A table
(operation "args" "in" "sequence") ; An s-expression (in this case, as a function call)
("a" (print "Hello, world!") (write "Test") [1 2 3]) ; Another s-expression (since operation isn't a variable, when processed, will process the operation and all arguments but return last argument's processed value (or the operation's processed value if there are no arguments))
```

# The standard library

A set of external functions that you can use to make your program work.

## print

Processes its arguments and prints all of them to the terminal in sequence.

Usage:

```lisp
(print "Hello, world!" "Another line" 56 ["This" "is" "a" "list"])
```

Output:

```
Hello, world!
Another line
56
[This, is, a, list]
```

## write

Processes its arguments and writes all of them to the terminal in sequence (seperated by space).

Usage:

```lisp
(write "Hello, world!" "Another thing" 56 ["This" "is" "a" "list"])
```

Output:

```
Hello, world! Another thing 56 [This, is, a, list]
```

## read

Reads a line from the terminal and returns it.

Usage:

```lisp
(read) ; This reads a line from terminal and returns it.
```

## exit

Exits with an exit code of 0

Usage:

```lisp
(exit) ; Exits the program
```

## if

Evaluates the condition (aka first argument), then returns the 2nd argument (processed) if the condition is a `true` boolean, otherwise returns `null`.

Usage:

```lisp
; This reads a line, checks if it's equal to exit, and if so, exits.
(if (= (read) "exit") (exit))
```

## if-else

Like `if`, but takes an extra 3rd argument that is returned if the condition is not `true`.

Usage:

```lisp
(if-else (= (read) "exit") (exit) (print "Ok, not exiting"))
```

## unless

Like `if`, but only evaluates the 2nd argument if it the condition **is not** a `true` boolean.

Usage:

```lisp
(unless (= (read) "dont exit") (exit))
```

## +

It takes 2 arguments and adds them up (if the process fails due to invalid combination, it returns the 1st argument).

Valid combinations:

- number + number -> number
- string + string -> string
- regex + regex -> regex
- list + list -> list (as if it was appending)
- table + table -> table (by merging)

## -

Like `+`, but subtracts, and thus has less combinations:

- number - number -> number
- string - string -> string (removes first occurance of 2nd string from 1st)
- regex - regex -> regex (like string operations but on the pattern's code)
- string - regex -> string (removes first match of pattern)

## \*

Like `+`, but multiplies, and thus only works on numbers.

## /

Like `*`, but divides. Still only works on numbers.

## %

Like `%`, but gives the remainder. Still only works on numbers.

## ^

Like `^`, but raises the first argument to the 2nd. Still only works on numbers.

## =

Takes 2 arguments. Returns if they are equal.

In the case of an invalid combination, it returns if they are the same object in memory.

Valid combinations are:

- bool & bool (if they are both the same type of boolean)
- number & number (if they are the same number)
- string & string (if they have the same contents)
- string & regex (if there is a match in the string)
- regex & regex (if they are the same pattern)

## !=

The opposite of `=`

## \>

Takes 2 arguments. Only works on numbers, returns if the 1st is greater than the 2nd.

## \<

Like `\>`, but checks if the 1st is less than the 2nd.
