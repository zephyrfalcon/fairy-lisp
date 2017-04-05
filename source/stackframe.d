// stackframe.d

import std.stdio;
import errors;
import tools;
import types;

abstract class StackFrameHelper {
    void Receive(LispObject x) {
        throw new NotImplementedError("abstract method");
    }
}

class StackFrame {
    LispObject original_expr;       // the original Lisp expression
    LispObject[] to_be_evaluated;   // yet to be evaluated
    LispObject[] evaluated;         // what we evaluated so far
    bool is_atomic;                 // is the original expression atomic
    LispEnvironment env;            // environment that the expression will be
                                    // evaluated in
    StackFrameHelper aux_data = null;

    this(LispObject expr, LispEnvironment env) {
        this.original_expr = expr;
        this.env = env;
        this.evaluated = [];
        if (auto p = cast(LispPair) expr) {
            try {
                this.to_be_evaluated = p.ToArray();
            } catch (ImproperListError e) {
                // do nothing, improper lists cannot be put in to_be_evaluated
                this.to_be_evaluated = [];
            }
            this.is_atomic = false;
        } else {
            this.to_be_evaluated = [];
            this.is_atomic = true;
        }
    }

    // return true if we haven't evaluated anything yet. this is important
    // when evaluating pairs (lists), since the first element of the list is
    // the operator (or it might be the name of a special form)
    bool IsUnevaluated() {
        return this.evaluated.length == 0;
    }

    // are we done evaluating all the parts of the expression in this stack frame?
    bool IsDone() {
        return (!this.is_atomic && this.to_be_evaluated.length == 0) 
            || (this.is_atomic && this.evaluated.length == 1);
    }

    void Print(int number) {
        writefln("---frame %d---", number);
        writefln("  %s -- %s", this.is_atomic ? "atomic" : "compound",
                               this.IsDone() ? "done" : "not done");
        writefln("  expression: %s", this.original_expr.Repr());
        writefln("  evaluated: %s", LispTypeListAsReprs(this.evaluated));
        writefln("  to be evaluated: %s", LispTypeListAsReprs(this.to_be_evaluated));
    }
}


