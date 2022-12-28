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
