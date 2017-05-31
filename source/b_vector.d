// b_vector.d

import errors;
import interpreter;
import types;

// (MAKE-VECTOR size [default])
LispObject b_make_vector(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto size = cast(LispInteger) fargs.args[0]) {
        LispObject _default = FALSE();
        if (fargs.rest_args.length > 0) {
            _default = fargs.rest_args[0];
        }
        auto vec = new LispVector(size.value, _default);
        return vec;
    } else
        throw new XTypeError("MAKE-VECTOR", "integer", fargs.args[0]);
}

// (LIST->VECTOR list)
LispObject b_list_to_vector(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto list = cast(LispList) fargs.args[0]) {
        LispObject[] stuff = list.ToArray();
        return new LispVector(stuff);
    } else
        throw new XTypeError("LIST->VECTOR", "list", fargs.args[0]);
}

// (VECTOR->LIST vector)
LispObject b_vector_to_list(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto vec = cast(LispVector) fargs.args[0]) {
        return LispList.FromArray(vec.values);
    } else
        throw new XTypeError("VECTOR->LIST", "vector", fargs.args[0]);
}

