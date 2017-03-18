// test_interpreter.d

import interpreter;
import tools_test;
import types;

// test EvalString()
unittest {
    auto intp = new Interpreter();
    auto results = intp.EvalString("3");
    AssertEquals(results.length, 1);
    AssertEquals(results[0], new LispInteger(3));

    // TODO: multiple expressions in string
}

