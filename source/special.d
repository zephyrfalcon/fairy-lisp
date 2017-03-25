// special.d
// Implementations of special forms.

import std.stdio;
import errors;
import interpreter;
import stackframe;
import types;

LispObject sf_quote(Interpreter intp, LispEnvironment env, LispObject[] args) {
    return args[1];  // return the first argument as-is
}

// currently only: (DEFINE <name> <value>)
LispObject sf_define(Interpreter intp, LispEnvironment env, LispObject[] args) {
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

SpecialFormSig[dstring] GetSpecialForms() {
    SpecialFormSig[dstring] forms = [
        "define": &sf_define,
        "do": &sf_do,
        "if": &sf_if,
        "lambda": &sf_lambda,
        "quote": &sf_quote,
    ];
    return forms;
}
