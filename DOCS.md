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

Also, functions can't read locals outside of their body. If you need them to have access to a value defined "outside", use globals.

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

A set of external functions and macros that you can use to make your program work.

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

Like `/`, but gives the remainder. Still only works on numbers.

## ^

Like `*`, but raises the first argument to the 2nd. Still only works on numbers.

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

Like `>`, but checks if the 1st is less than the 2nd.

## !

Takes 1 argument. If it's processed value is a boolean, returns its opposite. If not, it returns `false`.

## lambda

Takes 2 arguments: A list of parameters and the function body.

Usage:

```lisp
(var x (lambda [arg1 arg2 arg3] (print arg1 arg2 arg3)))
; Prints Prints 5, then 3, then 2.
(x 5 3 2)
```

## fn

Takes 3 arguments: A name, a list of parameters and the function body.

Defines a local function.

Usage:

```lisp
(fn my-function [arg1] (
  (print arg1)
  arg1
))

; Prints 5 twice.
(print (my-function 5))
```

## global-fn

Like `fn`, but defines a global.

## macro

Takes name and body. Defines a local macro.

Usage:

```lisp
(macro my-macro (
  (pring @args)
  ["list" @args]
))
```

## global-macro

Like `macro`, but defines a global macro.

## and

Returns the boolean AND operation

## or

Returns the boolean OR operation

## list-get

Returns a value from a list.

Usage:

```lisp
; Prints 3
(print (list-get [5 3 2] 1))
```

## list-set

Returns a copy of a list except a value was overwritten at an index.
If the copy wasn't big enough, a bunch of `null`s get added at the end to make space for that index.
If the index is invalid for another reason, the list is returned as is (no copying happens).

Usage:

```lisp
; Define original x
(var x [5 3 9])
; Define a new x
(var x (list-set x 1 0))
; Prints [5, 0, 9]
(print x)
```

## list-size

Returns the length of a list.

## list-remote-at

Takes a list and an index, returns a new list copy with that index removed.

## table-get

Gets a value from a table by key (checked by tostring-equality).

## table-set

Returns a new table with a value at a key created with or replaced by a specified value.

## table-size

Returns the amount of elements in a table.

## read-file

Takes a file path.
Returns the string contents of a file. If the file does not exit, returns an empty string.

## write-file

Takes a file path and content to write.
Overwrites the content of that file with the content to write.

## create-file

Takes a file path.
Creates the file if it doesn't exist.

## delete-file

Takes a file path.
Deletes the file if it exists.

## list-dir

Takes a directory path.
Returns the paths of all the files inside of the directory.

## create-dir

Takes a directory path.
Creates a directory.

## delete-dir

Takes a directory path.
Delete the directory.

## eval

Takes a string, and parses it as a Glue value and also returns its processed values.

## var

You've probably already seen this. Takes a variable name and value. Processes the value and pushes a new variable onto the local stack a variable of that name with the value.

## typeof

Returns as a string the type of a value.

Usage:

```lisp
(typeof null) ; null
(typeof 5) ; number
(typeof "") ; string
(typeof [5 3 2]) ; list
(typeof {"key" 5}) ; table
(typeof typeof) ; function
(macro my-macro ["list" @args]) ; Just a local macro
(typeof my-macro) ; macro
```

## tostring

Takes 1 argument. Returns its stringified version.

## tonumber

Takes 1 argument. Tries to turn it from string to number. If this process fails, returns null.

## import

Takes 1 argument. A file path.
Its the equivalent to this:

```lisp
(fn import [path] (
  (eval (read-file path))
))
```

## math-floor

Floors a number.

## math-ceil

Ceils a number.

## math-round

Rounds a number.

## read-var

Takes a string value and reads it as a variable.

## global

Like `var`, but sets a global with that name to that value.

## for-macros

Takes 1 (processed) argument. Returns its AST.

## for-macros-unprocessed

Takes 1 (unprocessed) argument. Returns its AST.
This means if you try to read a variable, it gives you a variable read, not the AST of the value.

## fn-body

Takes 1 argument. A function. Returns the AST of the body.

## fn-args

Takes 1 argument. A function. Returns a list of argument names.

## for

A for loop.

It takes 4 arguments. A setup, a condition, a step, and a body.

It first processes the setup.
Then, it keeps processing the condition. If it's not a `true` boolean, the loop ends. If it is a `true` boolean, it processes the body, then the step, then repeats.

Returns the last value the body had (`null` if it never ran).

## while

A while loop.

It takes 2 arguments. A condition, and a body.

It's like a for loop with no setup and no step.

## for-each

A foreach loop.

Processes the first argument, then if it is a list or table, iterates over its key-value pairs and parses the 3rd argument.
The 2nd argument is just a parameter list for the key and value parameter names.

### Small note on the loops

Every local defined inside of the loops is not removed. It is kept.

## disassemble

Takes one argument. Turns it into a string as Glue code.

## disassemble-code

Takes one argument. An AST. Disassembles it into actual Glue code.

## disassemble-ast

Turns its arguments (treated as ASTs) into a list of (processed) values.

## disassemble-ast-code

Turns its arguments (treated as ASTs) into a list of (unprocessed) values.
This can also cause this weird behavior:

```lisp
(var x (disassemble-ast-code ["var" "y"]))
; Prints [null] as expected
(print x)

(var y 5)

; Prints [5]. Although x never changed,
; x stored code that was now executed.
(print x)
```

The above behavior can also be exploited to get information about a function's context.
For example, it can be used to get a value of one of its locals by setting a global to it.
This is a fun little side-effect of `disassemble-ast-code`.

Please note: The behavior can be counter-intuitive. This behavior is left to the internals of the interpreter, which means this behavior may also not be standard if someone makes another interpreter with a different way of internally handling things.

## str-split

Takes a string and a seperator.
If the seperator is a RegEx, it splits it into matches.
If the seperator is something else, it stringifies it and then splits it by that.

Returns a list of the split parts.

## str-len

Takes a string and just returns its length.

## ascii

Takes one argument. If it is a string (and is not empty), returns the ASCII code of the first character.
If it is a number, returns the ASCII character of the number.
If it is an invalid value, returns null.

## struct

A macro. Takes a variable name, and list of fields, and automatically generates a constructor.

Usage:

```lisp
(struct MyStruct [x y z])
(print (MyStruct 506 23890 "Epic")) ; Prints {x: 506, y: 23890, z: Epic}
```

## field

A macro. Can read from or write to a field from a table (or struct) by name.

Usage:

```lisp
(print (field {"x" 50} x)) ; Prints 50
(print (field {"x" 50} x 2000)) ; Prints {x: 2000}
```
