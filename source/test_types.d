// test_types.d

import std.array : appender;
import std.format : formattedWrite;
import std.stdio;
import types;

void AssertEquals(dstring actual, dstring expected) {
    auto writer = appender!dstring();
    formattedWrite(writer, "Actual result: %s\nExpected: %s\n", actual, expected);
    if (actual != expected)
        stderr.writefln(writer.data());
    assert(actual == expected);
}

/* test Repr() */
unittest {

    /* empty list */
    LispObject e = new LispEmptyList();
    AssertEquals(e.Repr(), "()");

    /* proper list */
    auto l1 = new LispPair(new LispSymbol("foo"),
                  new LispPair(new LispSymbol("bar"), e));
    AssertEquals(l1.Repr(), "(foo bar)");
    auto l2 = new LispPair(new LispSymbol("quux"), l1);
    AssertEquals(l2.Repr(), "(quux foo bar)");
    auto l3 = new LispPair(e, l1);
    AssertEquals(l3.Repr(), "(() foo bar)");

    /* improper list */
    auto p = new LispPair(new LispSymbol("a"), new LispSymbol("b"));
    AssertEquals(p.Repr(), "(a . b)");
    auto p2 = new LispPair(new LispSymbol("z"), p);
    AssertEquals(p2.Repr(), "(z a . b)");

}

