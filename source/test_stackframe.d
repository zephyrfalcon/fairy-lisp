// test_stackframe.d

import stackframe;
import tools_test;
import types;

// atomic stack frame
unittest {
    LispObject expr = new LispSymbol("z");
    StackFrame sf = new StackFrame(expr, null);
    AssertEquals(sf.is_atomic, true);
    AssertEquals(sf.original_expr, expr);
    AssertEquals(sf.to_be_evaluated, []);
    AssertEquals(sf.evaluated, []);
}

// compound stack frame
unittest {
    LispObject expr = new LispPair(new LispSymbol("y"), NIL());
    StackFrame sf = new StackFrame(expr, null);
    AssertEquals(sf.is_atomic, false);
    AssertEquals(sf.original_expr, expr);
    AssertEquals(sf.to_be_evaluated, [new LispSymbol("y")]);
    AssertEquals(sf.evaluated, []);
}
