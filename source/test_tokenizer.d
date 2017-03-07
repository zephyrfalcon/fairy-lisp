// test_tokenizer.d

import std.array : appender;
import std.format : formattedWrite;
import std.stdio;
import tokenizer;

void AssertTokensEqual(dstring[] actual, dstring[] expected) {
    auto writer = appender!dstring();
    formattedWrite(writer, "Actual result: %s\nExpected: %s\n", actual, expected);
    if (actual != expected)
        stderr.writefln(writer.data());
    assert(actual == expected);
}

unittest {
    AssertTokensEqual(tokenize("foo"), ["foo"]);
    AssertTokensEqual(tokenize("a b c"), ["a", "b", "c"]);
    AssertTokensEqual(tokenize("  лиса 1 "), ["лиса", "1"]);
    AssertTokensEqual(tokenize("(a b)"), ["(", "a", "b", ")"]);
    AssertTokensEqual(tokenize("'x"), ["'", "x"]);
}

