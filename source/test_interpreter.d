// test_interpreter.d

import interpreter;
import tools_test;
import types;

// test EvalString()
unittest {
    auto intp = new Interpreter();
    auto results = intp.EvalString("3", intp.global_env);
    AssertEquals(results.length, 1);
    AssertEquals(results[0], new LispInteger(3));

    // TODO: multiple expressions in string
}

// test if builtins exist
unittest {
    auto intp = new Interpreter();

    // check if the built-in symbol 'true' exists
    auto results = intp.EvalString("true", intp.global_env);
    AssertEquals(results.length, 1);
    AssertEquals(results[0], TRUE());

    // check if the built-in function '+' exists
    results = intp.EvalString("+", intp.global_env);
    AssertEquals(results.length, 1);
    if (auto bf = cast(LispBuiltinFunction) results[0]) {
        AssertEquals(bf.name, "+");
    } else Fail("not a built-in function");
}

