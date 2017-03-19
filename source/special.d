// special.d
// Implementations of special forms.

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

SpecialFormSig[dstring] GetSpecialForms() {
    SpecialFormSig[dstring] forms = [
        "define": &sf_define,
        "lambda": &sf_lambda,
        "quote": &sf_quote,
    ];
    return forms;
}
