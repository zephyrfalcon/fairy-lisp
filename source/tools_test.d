// tools_test.d
// Auxiliary routines for testing.

import std.array : appender;
import std.format : formattedWrite;
import std.stdio;
import types;

// TODO: you notice they all look the same... maybe we can make this more
// generic with templates?

void Fail(string msg) {
    stderr.writeln(msg);
    assert(false, msg);
}

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

void AssertEquals(string[] actual, string[] expected) {
    auto writer = appender!string();
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

void AssertEquals(ulong actual, ulong expected) {
    auto writer = appender!dstring();
    formattedWrite(writer, "Actual result: %s\nExpected: %s\n", actual, expected);
    if (actual != expected)
        stderr.writefln(writer.data());
    //assert(equal(actual, expected));
    assert(actual == expected);
}

void AssertNull(Object o) {
    auto writer = appender!dstring();
    formattedWrite(writer, "Object is not null: %s", o);
    if (o !is null)
        stderr.writefln(writer.data());
    //assert(equal(actual, expected));
    assert(o is null);
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

