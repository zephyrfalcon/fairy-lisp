// test_environment.d

import std.exception;
import errors;
import tools_test;
import types;

// test environment creation
unittest {
    // new environment has no parent and no names
    LispEnvironment env = new LispEnvironment();
    AssertNull(env.parent);
    AssertEquals(env.names.length, 0);

    LispEnvironment env2 = new LispEnvironment(env);
    AssertEquals(env2.parent, env);
}

// simple environment usage
unittest {
    LispEnvironment e1 = new LispEnvironment();
    e1.Set("foo", new LispInteger(42));
    e1.Set("bar", new LispSymbol("bar"));
    AssertEquals(e1.names.length, 2);

    auto efr = e1.Find("foo");
    AssertEquals(efr.env, e1);
    AssertEquals(efr.value, new LispInteger(42));

    assertThrown!EnvironmentKeyException(e1.Find("xyzzy"));
    assertThrown!EnvironmentKeyException(e1.Get("xyzzy"));
}
