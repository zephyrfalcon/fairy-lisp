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
    dstring[] argnames = [];
    if (auto list = cast(LispList) args[1]) {
        LispObject[] names = list.ToArray();
        foreach(x; names) {
            if (auto sym = cast(LispSymbol) x) {
                argnames ~= sym.value;
            } else throw new TypeError("LAMBDA: argument names must be symbols");
        }
    } else throw new TypeError("LAMBDA: first argument must be a list");
    LispObject[] fbody = args[2..$];
    auto uf = new LispUserDefinedFunction(argnames, fbody, env);
    return uf;
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

SpecialFormSig[dstring] GetSpecialForms() {
    SpecialFormSig[dstring] forms = [
        "cond": &sf_cond,
        "define": &sf_define,
        "do": &sf_do,
        "if": &sf_if,
        "lambda": &sf_lambda,
        "quote": &sf_quote,
    ];
    return forms;
}
