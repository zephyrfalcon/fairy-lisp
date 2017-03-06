// tools_test.d
// Auxiliary routines for testing.

import std.array : appender;
import std.format : formattedWrite;
import std.stdio;
import types;

// TODO: you notice they all look the same... maybe we can make this more
// generic with templates?

void AssertEquals(dstring actual, dstring expected) {
    auto writer = appender!dstring();
    formattedWrite(writer, "Actual result: %s\nExpected: %s\n", actual, expected);
    if (actual != expected)
        stderr.writefln(writer.data());
    assert(actual == expected);
}

void AssertEquals(dstring[] actual, dstring[] expected) {
    auto writer = appender!dstring();
    formattedWrite(writer, "Actual result: %s\nExpected: %s\n", actual, expected);
    if (actual != expected)
        stderr.writefln(writer.data());
    assert(actual == expected);
}

void AssertEquals(LispObject[] actual, LispObject[] expected) {
    auto writer = appender!dstring();
    formattedWrite(writer, "Actual result: %s\nExpected: %s\n", actual, expected);
    if (actual != expected)
        stderr.writefln(writer.data());
    //assert(equal(actual, expected));
    assert(actual == expected);
}

void AssertEquals(LispObject actual, LispObject expected) {
    auto writer = appender!dstring();
    formattedWrite(writer, "Actual result: %s\nExpected: %s\n", actual.Repr(),
                   expected.Repr());
    if (actual != expected)
        stderr.writefln(writer.data());
    //assert(equal(actual, expected));
    assert(actual == expected);
}

