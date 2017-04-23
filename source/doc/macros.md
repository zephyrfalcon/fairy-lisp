### Macros

A *macro* is essentially just a function that takes an unevaluated expression,
and transforms it according to certain rules.

* macro expansion
  * *macroexpand-hook*
  * macroexpand
  * macroexpand-1
  * macroexpand-all
  * special forms are expanded differently

* eval
* macro expansion at the REPL

* macros don't evaluate the expression given, but might call other functions
  (non-macros) to transform the expression, that do evaluate their arguments

* under the hood, a macro object is the same as a function object
  * only difference is when it is called (at macroexpansion time, i.e.
    directly after read time; as opposed to regular functions which are called
    at evaluation time)
    * directly after we read an expression, any macros in it are expanded
      before the expression is evaluated

* macros accept rest arguments

* macros can be called with `apply`, in which case they are treated like
  ordinary functions

#### Open issues

* macros should be able to accept keyword arguments as well, but this has not
  been implemented yet

