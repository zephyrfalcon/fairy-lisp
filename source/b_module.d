// b_module.d

import errors;
import interpreter;
import tools;
import types;

// (MAKE-MODULE [name [env]])
LispObject b_make_module(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    auto modenv = new LispEnvironment(intp.builtin_env);
    auto mod = new LispModule(modenv);
    return mod;
}

