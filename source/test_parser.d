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

    x = tokenize_and_parse("(a b c)");
    AssertEquals(x.result, new LispPair(new LispSymbol("a"), new LispPair(new
                    LispSymbol("b"), new LispPair(new LispSymbol("c"), NIL()))));
    AssertEquals(x.rest_tokens, []);

    x = tokenize_and_parse("((a (b) c () (d (e (f g))))) bogus");
    AssertEquals(x.result.Repr(), "((a (b) c () (d (e (f g)))))");
    AssertEquals(x.rest_tokens, ["bogus"]);
}

/* test QUOTE */
unittest {
    ParserResult x = tokenize_and_parse(" 'p ");
    AssertEquals(x.result, new LispPair(new LispSymbol("quote"), new
                LispPair(new LispSymbol("p"), NIL())));
    AssertEquals(x.rest_tokens, []);

    x = tokenize_and_parse("'(hello kitty)");
    AssertEquals(x.result.Repr(), "(quote (hello kitty))");
}

// test CreateFromToken()
unittest {
    LispObject o1 = CreateFromToken("42");
    if (auto i1 = cast(LispInteger) o1) {
        AssertEquals(i1.value, 42);
    } else {
        Fail("could not convert token to LispInteger");
    }
}
