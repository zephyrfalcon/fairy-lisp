// test_callstack.d

import callstack;
import stackframe;
import test_tools;
import types;

unittest {
    CallStack cs = new CallStack();
    LispObject expr = new LispInteger(3);
    LispEnvironment env = new LispEnvironment();
    cs.Push(new StackFrame(expr, env));
}
