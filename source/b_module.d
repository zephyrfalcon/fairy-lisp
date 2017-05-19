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

// (MODULE-ENV-SET! module env)
LispObject b_module_env_set(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto mod = cast(LispModule) fargs.args[0]) {
        if (auto newenv = cast(LispEnvironment) fargs.args[1]) {
            mod.env = newenv;
            return mod;
        } else
            throw new XTypeError("MODULE-ENV-SET!", "environment", fargs.args[1]);
    } else
        throw new XTypeError("MODULE-ENV-SET!", "module", fargs.args[0]);
}

// (MODULE-NAME module)
LispObject b_module_name(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto mod = cast(LispModule) fargs.args[0]) {
        return LispSymbol.Get(mod.name);
    } else
        throw new XTypeError("MODULE-NAME", "module", fargs.args[0]);
}

// (MODULE-NAME-SET! module name)
LispObject b_module_name_set(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto mod = cast(LispModule) fargs.args[0]) {
        if (auto sym = cast(LispSymbol) fargs.args[1]) {
            mod.name = sym.value;
            return mod;
        } else
            throw new XTypeError("MODULE-NAME-SET!", "symbol", fargs.args[1]);
    } else
        throw new XTypeError("MODULE-NAME-SET!", "module", fargs.args[0]);
}

// (MODULE-PATH module)
LispObject b_module_path(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto mod = cast(LispModule) fargs.args[0]) {
        return new LispString(mod.path);
    } else
        throw new XTypeError("MODULE-PATH", "module", fargs.args[0]);
}

// (MODULE-PATH-SET! module path)
LispObject b_module_path_set(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto mod = cast(LispModule) fargs.args[0]) {
        if (auto path = cast(LispString) fargs.args[1]) {
            mod.path = path.value;
            return mod;
        } else
            throw new XTypeError("MODULE-PATH-SET!", "string", fargs.args[0]);
    } else
        throw new XTypeError("MODULE-PATH-SET!", "module", fargs.args[0]);
}
