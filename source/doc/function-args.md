### Function arguments

* regular arguments
* rest arguments
* keyword arguments

* all functions (built-in and user-defined) support these
* arity of function is important
  * hardcoded for builtins
  * for user-defined functions, this is simply the number of arguments
    specified in the argument list

* keyword arguments are scanned before we evaluate a function call form
  * then when all the part of that form have been evaluated, we determine if a
    keyword in that form is a keyword argument, or a keyword object
  * regular, rest and keyword arguments are parsed before we call the function

* arguments show up inside function body in different ways
  * regular arguments map to the argument names given
  * rest arguments are in a list called `%rest`
  * keyword arguments are in a dictionary called `%keywords` (symbol -> value)

----

*(very much a work in progress)*

Keywords are much like symbols, but their names start with a colon, e.g.
`:foo`. They evaluate to themselves.

Keywords can be used to pass *keyword arguments* to function calls. All
functions support this (but whether they do anything with the keyword
arguments that are passed this way, is up to the function).

Keyword arguments consist of a keyword followed by a value (which can be any
expression). For example:

```
(f 1 :foo 2)
```

Here, `f` takes one regular argument (1) and one keyword argument (`:foo`,
which has the value 2).

Inside the function, keyword arguments are passed in a *keyword dictionary*
called `%keywords`. The keyword dictionary maps *symbols* (!) to values
(rather than keywords to values, as this would make it harder to access the
values).


