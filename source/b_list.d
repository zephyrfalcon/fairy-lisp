// b_list.d
// Built-in functions for lists.

import errors;
import interpreter;
import types;

LispObject b_cons(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    return new LispPair(fargs.args[0], fargs.args[1]);
}

LispObject b_car(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto p = cast(LispPair) fargs.args[0]) {
        return p.head;
    } else
        throw new TypeError("CAR: argument must be a list");
}

LispObject b_cdr(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto p = cast(LispPair) fargs.args[0]) {
        return p.tail;
    } else
        throw new TypeError("CDR: argument must be a list");
}

LispObject b_reverse(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto list = cast(LispList) fargs.args[0]) {
        auto rev = list.Reverse();
        return rev;
    } else
        throw new TypeError("list expected");
}

LispObject b_append(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto list1 = cast(LispList) fargs.args[0]) {
        if (auto list2 = cast(LispList) fargs.args[1]) {
            if (list1 is NIL()) return list2;
            if (list2 is NIL()) return list1;
            LispObject[] stuff = list1.ToArray();
            LispPair prev, head;
            foreach(i, obj; stuff) {
                // make new cons cell
                auto new_pair = new LispPair(obj, NIL());
                // hook up to previous cons cell, if any
                if (i == 0) head = new_pair;  // remember first cons cell
                if (i > 0 && prev !is null)
                    prev.tail = new_pair;
                prev = new_pair;
            }
            prev.tail = list2;
            return head;
        } else
            throw new TypeError("list expected");
    } else 
        throw new TypeError("list expected");
}

LispObject b_length(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto list = cast(LispList) fargs.args[0]) {
        return new LispInteger(list.Length());
    } else
        throw new TypeError("list expected");
}
