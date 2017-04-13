// b_env.d
// Built-in functions dealing with environments.

import errors;
import interpreter;
import types;

// (ENV-GET env name [default])
LispObject b_env_get(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto this_env = cast(LispEnvironment) fargs.args[0]) {
        if (auto name = cast(LispSymbol) fargs.args[1]) {
            try {
                LispObject result = this_env.Get(name.value);
                return result;
            } catch (EnvironmentKeyException e) {
                if (fargs.rest_args.length > 0) 
                    return fargs.rest_args[0];
                throw e;
            }
        } else
            throw new TypeError("ENV-GET: name must be a symbol");
    } else 
        throw new TypeError("ENV-GET: first argument must be an environment");
}

// return the current environment
LispObject b_current_env(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    return env;
}

