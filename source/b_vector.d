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

// (VECTOR-GET vec idx [default])
LispObject b_vector_get(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto vec = cast(LispVector) fargs.args[0]) {
        if (auto idx = cast(LispInteger) fargs.args[1]) {
            if (fargs.rest_args.length > 0) {
                if (idx.value >= 0 && idx.value < vec.values.length)
                    return vec.values[idx.value];  
                else 
                    return fargs.rest_args[0];
            } else {
                return vec.values[idx.value];
            }
        } else
            throw new XTypeError("VECTOR-GET", "integer", fargs.args[1]);
    } else
        throw new XTypeError("VECTOR-GET", "vector", fargs.args[0]);
}

// (VECTOR-SET! vec idx value)
LispObject b_vector_set(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto vec = cast(LispVector) fargs.args[0]) {
        if (auto idx = cast(LispInteger) fargs.args[1]) {
            vec.values[idx.value] = fargs.args[2];
            return vec;
        } else
            throw new XTypeError("VECTOR-GET", "integer", fargs.args[1]);
    } else
        throw new XTypeError("VECTOR-GET", "vector", fargs.args[0]);
}

LispObject b_vector_length(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto vec = cast(LispVector) fargs.args[0]) {
        return new LispInteger(cast(int) vec.values.length);
    } else
        throw new XTypeError("VECTOR-LENGTH", "vector", fargs.args[0]);
}
