// b_module.d

import errors;
import interpreter;
import tools;
import types;

// (MAKE-MODULE name)
// TODO: add optional env argument?
LispObject b_make_module(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto sym = cast(LispSymbol) fargs.args[0]) {
        auto modenv = new LispEnvironment(intp.builtin_env);
        auto mod = new LispModule(sym.value, modenv);
        return mod;
    } else
        throw new XTypeError("MAKE-MODULE", "symbol", fargs.args[0]);
}

// (MODULE-ENV module)
LispObject b_module_env(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto mod = cast(LispModule) fargs.args[0]) {
        return mod.env;
    } else
        throw new XTypeError("MODULE-ENV", "module", fargs.args[0]);
}

