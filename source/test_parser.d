// test_parser.d

import types;
import parser;
import tokenizer;
import tools_test;

ParserResult tokenize_and_parse(dstring text) {
    dstring[] tokens = tokenize(text);
    ParserResult pr = parse(tokens);
    return pr;
}

/* test parser, general */
unittest {
    ParserResult x = tokenize_and_parse("quux");
    AssertEquals(x.result, new LispSymbol("quux"));
    AssertEquals(x.rest_tokens, []);

    x = tokenize_and_parse("()");
    AssertEquals(x.result, NIL());
    AssertEquals(x.rest_tokens, []);

    x = tokenize_and_parse("x y");
    AssertEquals(x.result, new LispSymbol("x"));
    AssertEquals(x.rest_tokens, ["y"]);
}

