import tokenizer;

void AssertTokensEqual(dstring[] actual, dstring[] expected) {
    assert(actual == expected);
}

unittest {

    dstring[] tokens = tokenize("foo");
    //assert(tokens == cast(dstring[])["foo"]);
    AssertTokensEqual(tokens, ["foo"]);

    AssertTokensEqual(tokenize("a b c"), ["a", "b", "c"]);
}
