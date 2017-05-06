// test_environment.d

import std.algorithm.sorting;
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
    e1.Set("bar", LispSymbol.Get("bar"));
    AssertEquals(e1.names.length, 2);

    auto efr = e1.Find("foo");
    AssertEquals(efr.env, e1);
    AssertEquals(efr.value, new LispInteger(42));

    assertThrown!EnvironmentKeyException(e1.Find("xyzzy"));
    assertThrown!EnvironmentKeyException(e1.Get("xyzzy"));

    e1.Update("foo", new LispInteger(43));
    AssertEquals(e1.Get("foo"), new LispInteger(43));
    assertThrown!EnvironmentKeyException(e1.Update("xyzzy", NIL()));

    // create a new environment with e1 as parent
    LispEnvironment e2 = new LispEnvironment(e1);
    e2.Set("foo", new LispInteger(100)); // we have our own foo

    AssertEquals(e2.Get("foo"), new LispInteger(100));
    AssertEquals(e2.parent.Get("foo"), new LispInteger(43));
    AssertEquals(e1.Get("foo"), new LispInteger(43));
    AssertEquals(e2.Get("bar"), LispSymbol.Get("bar"));

    e2.Update("bar", LispSymbol.Get("quux"));
    AssertEquals(e2.Get("bar"), LispSymbol.Get("quux"));
    AssertEquals(e1.Get("bar"), LispSymbol.Get("quux"));
    assertThrown!EnvironmentKeyException(e2.GetLocal("bar"));

    efr = e2.Find("bar");
    AssertEquals(efr.env, e1);

    dstring[] e1_names = e1.GetLocalNames();
    dstring[] e2_names = e2.GetLocalNames();
    e1_names.sort();
    e2_names.sort();
    AssertEquals(e1_names, ["bar", "foo"]);
    AssertEquals(e2_names, ["foo"]);
}


