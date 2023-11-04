# Glue Docs

Docs on the Glue programming language.

<strong>
  <h3 style="color: yellow;">Warning: This page is under construction!</h3>  
</strong>

# Important notes

> _Stuff you should probably know before writing any code_

## 1. _Code is Data_

> _All code written in Glue shall be treated equivalent to unprocessed data_

In Glue, code is just data in an "unprocessed" state. When data is "processed", it means it is simplified to its simplest possible form.

It is possible to store code in variables and have it execute when the variable is read. Although, this can cause **_counter-intuitive behavior_**.

## 2. _Mutability_

> _Variables in Glue can change what value they hold, but data in Glue can't change its state_

In Glue, variables can change what value they hold inside. However, **data** (aka lists, tables, etc.) is **immutable**.

This means, if you have a variable called `x` which holds a list of 5 numbers, you can set `x` to a new list, but you can't change the list itself.

## 3. _Macros and Functions_

> _Macros generate code from code, functions generate data from data_

Macros don't have named arguments. They have a local called `@args` which has a list of ASTs that are its arguments. It must return a new AST to be processed.

Functions have named arguments, and return processed data.

However, external functions (aka functions you didn't write in Glue) may only optionally process arguments.

## 4. _Variables Scopes_

> _Glue supports Lexical Scoping_

Glue supports <a href="https://en.wikipedia.org/wiki/Scope_(computer_science)#Lexical_scope">Lexical Scoping</a>.

This means a variable is scoped based on its **location** in code. This allows for intuitive usages of locals.

# Syntax

> _Glue has a LISP-like syntax_

Glue is based on **<a href="https://en.wikipedia.org/wiki/Lisp_(programming_language)">LISP</a>**, however, does not support M-Expressions. (brackets are used for something else)

## Comments

Just like in LISP, comments start with a `;`.

## Primitives

There are 5 primitives: Numbers (only real numbers), <a href="https://en.wikipedia.org/wiki/Boolean_data_type">booleans</a>, <a href="https://en.wikipedia.org/wiki/String_(computer_science)">strings</a> and <a href="https://en.wikipedia.org/wiki/Regular_expression">Regular Expressions</a>, and <a href="https://en.wikipedia.org/wiki/Null_pointer">null</a>.

They are written like so:

```lisp
"A string"
`a regex`
5.32 ; A number
true ; A boolean
null ; Null
```

Primitives are compared by value.

## Non-Primitives

These are non-primites, they're compared by memory address.

There are 2 non-primites: Lists and Tables.

Important note: Tables are indexed by any value, but it stringifies the value and looks for a match. Table look-ups are currently `O(N)`, where N is the amount of elements in the table. This means it might look through every element in the table for a key match. This is going ot be changed to a proper `hash-map` soon enough.

This also means that `"5"` and `5` will be mapped to the same thing even if they're not the same exact key.

They are written like so:

```lisp
[50 30 20 10] ; You separate expressions by space
{"field" "value" "field2" "value2"} ; Table
```

## Syntactic Sugar

There is syntactic sugar for field indexing.
In some places you can use field indexing instead of variables.
This will index a variable. This currently can only index variables, and only if they hold tables, otherwise returning the value of the variable.

They are written as so:

```lisp
test.field
```

# Standard Library

The **standard library** is a collection of functions you can use.
These can make your own useful.

## I/O

> I/O means Input / Output and it's how your program can get input and give an output.

### print

> Prints the values given as strings

Prints the values you give it. They are all printed on separate lines.

### write

> Writes the values given as strings

Writes out to the terminal the values you give it as strings. They do not add a "newline character" at the end so they are printed right after each other.

### read

> Reads a line from the terminal and returns it.

NOTE: because of grammar rules,
```lisp
read
```
Will give you the function and
```lisp
(read)
```
Will actually call the function.

### exit

> Terminates the program

Will exit with an exit code of 0 (which means success).
This is useful to terminate the program, for example:
```lisp
(if (= command "exit") (exit))
```

### if

> Performs basic conditional logic

It evaluates the first expression, and if that expression is equal to `true`, it will evalute and return the 2nd expression. If not, it will return `null`.

If that is too confusing, here's a simpler explanation:
```lisp
(if (= a 3) (print "Hi"))
```
This means "Evaluate the expression `(= a 3)`. If that is equal to `true`, then evaluate the expression `(print "Hi")`, which prints `Hi` to the console. If not, then this whole `if` expression is equal to null."

### if-else

> An equivalent to the ternary operator

This is just like `if` however if the first expression is not `true`, it will return the 3rd expression instead of `null`.

If `(if a b)` is the same as this Python code:
```py
if a:
  return b
else:
  return None
```

Then `(if-else a b c)` is the same as:
```py
if a:
  return b
else:
  return c
```

Except both of them can be used as expressions!

### unless

`(unless a b)` is the same as `(if-else a null b)`
