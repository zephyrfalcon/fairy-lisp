// stackframe.d

import types;

class StackFrame {
    LispObject original_expr;       // the original Lisp expression
    LispObject[] to_be_evaluated;   // yet to be evaluated
    LispObject[] evaluated;         // what we evaluated so far
    bool is_atomic;                 // is the original expression atomic
    // TODO: env
    // TODO: helper
}


