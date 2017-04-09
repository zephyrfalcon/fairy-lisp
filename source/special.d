// special.d
// Implementations of special forms.

import std.stdio;
import std.string;
import errors;
import interpreter;
import stackframe;
import tools;
import types;

LispObject sf_quote(Interpreter intp, LispEnvironment env, LispObject[] args) {
    return args[1];  // return the first argument as-is
}

// currently only: (DEFINE <name> <value>)
LispObject sf_define(Interpreter intp, LispEnvironment env, LispObject[] args) {
    if (auto sym = cast(LispSymbol) args[1]) {
        return _define_symbol(intp, env, args);
    } else if (auto p = cast(LispPair) args[1]) {
        return _define_function(intp, env, args);
    } else 
        throw new TypeError("DEFINE: invalid form");
}

LispObject _define_symbol(Interpreter intp, LispEnvironment env, LispObject[] args) {
    if (auto sym = cast(LispSymbol) args[1]) {
        StackFrame top = intp.callstack.Top();
        if (top.evaluated.length == 0) {
            auto sf = new StackFrame(args[2], top.env);
            intp.callstack.Push(sf);
            return null;  // evaluate via stack mechanism
        } else {
            // we've evaluated the value
            env.Set(sym.value, top.evaluated[0]);
            return top.evaluated[0];
        }
    } else 
        throw new TypeError("DEFINE: name must be a symbol");
}

LispObject _define_function(Interpreter intp, LispEnvironment env, LispObject[] args) {
    if (auto p = cast(LispPair) args[1]) {
        // (DEFINE (name ...args...) ...body...)
        if (args[2..$].length < 1)
            throw new Exception("DEFINE: body cannot be empty");
        LispObject[] fbody = args[2..$];
        dstring[] header = GetListOfSymbols(p.ToArray());
        if (header.length < 1)
            throw new Exception("DEFINE: function must have a name");
        dstring fname = header[0];
        dstring[] argnames = header[1..$];
        auto uf = new LispUserDefinedFunction(argnames, fbody, env, fname);
        env.Set(fname, uf);
        return uf;
    } else
        throw new TypeError("DEFINE: expected list of symbols");
}

LispObject sf_lambda(Interpreter intp, LispEnvironment env, LispObject[] args) {
    return _function("lambda", intp, env, args);
}

LispObject sf_macro(Interpreter intp, LispEnvironment env, LispObject[] args) {
    return _function("macro", intp, env, args);
}

LispObject _function(string type, Interpreter intp, LispEnvironment env, LispObject[] args) {
    dstring[] argnames = [];
    if (auto list = cast(LispList) args[1]) {
        LispObject[] names = list.ToArray();
        foreach(x; names) {
            if (auto sym = cast(LispSymbol) x) {
                argnames ~= sym.value;
            } else 
                throw new TypeError(
                        format("%s: argument names must be symbols", type));
        }
    } else 
        throw new TypeError(format("%s: first argument must be a list", type));

    LispObject[] fbody = args[2..$];
    if (type == "lambda") {
        return new LispUserDefinedFunction(argnames, fbody, env);
    } else if (type == "macro") {
        return new LispMacro(argnames, fbody, env);
    } else 
        throw new TypeError(format("Unknown type: %s", type));
}
 
LispObject sf_do(Interpreter intp, LispEnvironment env, LispObject[] args) {
    if (args.length <= 1)
        throw new Exception("DO: empty body is not allowed");
    StackFrame top = intp.callstack.Top();
    // we store the results of the evaluated expressions in
    // StackFrame.evaluated, so we know how many have been evaluated so far.
    // last one gets special treatment (TCO)
    if (top.evaluated.length == args.length-2) {
        intp.callstack.Pop();
        auto sf = new StackFrame(args[$-1], top.env);
        intp.callstack.Push(sf);
    } else {
        size_t idx = top.evaluated.length + 1;  // index of next expr to evaluate
        auto sf = new StackFrame(args[idx], top.env);
        intp.callstack.Push(sf);
    }
    return null;
}

LispObject sf_if(Interpreter intp, LispEnvironment env, LispObject[] args) {
    StackFrame top = intp.callstack.Top();
    if (top.evaluated.length == 0) {
        auto cond = args[1];
        auto newsf = new StackFrame(cond, env);
        intp.callstack.Push(newsf);
        return null;
    } else {
        auto result = top.evaluated[0];
        auto expr = result.IsTrue() ? args[2] : args[3];
        auto newsf = new StackFrame(expr, env);
        intp.callstack.Pop();  // remove current stack frame (TCO)
        intp.callstack.Push(newsf);
        return null;
    }
}

// (COND (cond1 expr1s...) (cond2 expr2s...) [(else ...)])
// a COND has a number of sub-expressions of the form (condition
// ..exprs..). whenever we evaluate a condition, the result goes onto
// frame.evaluated. if the condition is true, the corresponding
// expressions are evaluated on the stack, and no other parts of the COND
// are processed.
// if no condition is found that is true, the result is false.
//
// XXX possible optimization: single expressions do not need wrapped in DO...
LispObject sf_cond(Interpreter intp, LispEnvironment env, LispObject[] args) {
    auto top = intp.callstack.Top();

    if (top.evaluated.length > 0) {
        if (TruthValue(top.evaluated[$-1])) {
            // this condition is true
            // evaluate the corresponding expression(s) using TCO
            auto stuff = args[top.evaluated.length];
            if (auto list = cast(LispPair) stuff) {
                // wrap expression(s) up in a DO
                auto expr = new LispPair(new LispSymbol("do"), list.tail);
                auto sf = new StackFrame(expr, env);
                intp.callstack.Pop();
                intp.callstack.Push(sf);
                return null;
            } else
                throw new TypeError(
                        format("COND: invalid condition: %s", stuff.Repr()));
        }
    }

    // are there still parts left to be processed?
    if (top.evaluated.length == args.length-1) {
        // everything processed, we didn't find a matching condition
        return FALSE();
    } else {
        // process the next condition
        LispObject stuff = args[top.evaluated.length+1];
        if (auto list = cast(LispPair) stuff) {
            LispObject cond = list.head;
            // if condition is symbol "else", then it's considered true
            if (IsSymbol(cond, "else")) {
                // might as well push expression on the stack right now (TCO)
                auto expr = new LispPair(new LispSymbol("do"), list.tail);
                auto sf = new StackFrame(expr, env);
                intp.callstack.Pop();
                intp.callstack.Push(sf);
                return null;
            } else {
                // evaluate the condition
                auto sf = new StackFrame(cond, env);
                intp.callstack.Push(sf);
                return null;
            }
        } else 
            throw new TypeError(format("COND: invalid condition: %s", stuff.Repr()));
    }
}

class LetHelper: StackFrameHelper {
    LispEnvironment env;
    LispObject[] values_in;
    dstring next_name;
    this(LispObject[] values_in, LispEnvironment env) {
        this.values_in = values_in;
        this.env = env;
        this.next_name = "";
    }
    override void Receive(LispObject x) {
        this.env.Set(this.next_name, x);
    }
}

// (LET (..names..) ..body..)
// Unlike Lisp/Scheme's LET, the first parameter is a list whose values are
// alternately names and values to be bound to those names.
// E.g. (LET (a 1 b 2) ...)

/* How LET works internally:
   LET creates a new namespace. The names specified in LET's first argument 
   (a list) will be created in this namespace, one by one, so they can refer 
   to each other once they're defined. (Like Scheme's LET* but unlike its LET.)
   We need to evaluate the values associated with the names; to do this, we create
   an auxiliary data structure to keep track of what has been evaluated so far,
   and to store the new namespace. This is necessary because we will revisiting
   the sf_let function multiple times.
   The slice of expressions (name1 value1 name2 value2 ...) will be stored in
   aux.values_in. Whenever we call sf_let, if this slice is not empty, we take
   its first two elements (a name and an expression), then add the name to
   aux.strings, and put the expression up for evaluation.
   When the resulting value comes back (in top.evaluated), we add this to the
   new namespace (as stored in aux.env).
   When aux.values_in is empty, we evaluate the body in the new namespace, which
   now contains all the names+values specified in LET's first argument.
   (TCO is done here.)
*/
LispObject sf_let(Interpreter intp, LispEnvironment env, LispObject[] args) {
    auto top = intp.callstack.Top();

    if (top.aux_data is null) {
        if (auto header = cast(LispList) args[1]) {
            LispObject[] values = header.ToArray();
            auto newenv = new LispEnvironment(env);
            top.aux_data = new LetHelper(values, newenv);
        } else 
            throw new Exception("LET: invalid header");
    }

    if (auto aux = cast(LetHelper) top.aux_data) {
        if (aux.values_in.length >= 2) {
            if (auto sym = cast(LispSymbol) aux.values_in[0]) {
                aux.next_name = sym.value;
                auto sf = new StackFrame(aux.values_in[1], aux.env);
                intp.callstack.Push(sf);
                aux.values_in = aux.values_in[2..$];
                return null;
            } else 
                throw new TypeError("LET: name must be a symbol");
        } else if (aux.values_in.length == 1) {
            throw new Exception("LET: header must have even number of elements");
        } else {
            // done evaluating the header part
            // evaluate body in new environment with names bound in it (TCO)
            LispObject let_body = WrapExprsInDo(args[2..$]);
            auto sf = new StackFrame(let_body, aux.env);
            intp.callstack.Pop();
            intp.callstack.Push(sf);
            return null;
        }
    } else throw new Exception("?!");
}

SpecialFormSig[dstring] GetSpecialForms() {
    SpecialFormSig[dstring] forms = [
        "cond": &sf_cond,
        "define": &sf_define,
        "do": &sf_do,
        "if": &sf_if,
        "lambda": &sf_lambda,
        "let": &sf_let,
        "macro": &sf_macro,
        "quote": &sf_quote,
    ];
    return forms;
}
