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
    AssertEquals(x.result, LispSymbol.Get("quux"));
    AssertEquals(x.rest_tokens, []);

    x = tokenize_and_parse("()");
    AssertEquals(x.result, NIL());
    AssertEquals(x.rest_tokens, []);

    x = tokenize_and_parse("x y");
    AssertEquals(x.result, LispSymbol.Get("x"));
    AssertEquals(x.rest_tokens, ["y"]);

    x = tokenize_and_parse("(a b c)");
    AssertEquals(x.result, new LispPair(LispSymbol.Get("a"), new LispPair(
                    LispSymbol.Get("b"), new LispPair(LispSymbol.Get("c"), NIL()))));
    AssertEquals(x.rest_tokens, []);

    x = tokenize_and_parse("((a (b) c () (d (e (f g))))) bogus");
    AssertEquals(x.result.Repr(), "((a (b) c () (d (e (f g)))))");
    AssertEquals(x.rest_tokens, ["bogus"]);
}

/* test QUOTE */
unittest {
    ParserResult x = tokenize_and_parse(" 'p ");
    AssertEquals(x.result, new LispPair(LispSymbol.Get("quote"), 
                               new LispPair(LispSymbol.Get("p"), NIL())));
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

    LispObject o2 = CreateFromToken(`"hello world"`);
    if (auto s1 = cast(LispString) o2) {
        AssertEquals(s1.value, `hello world`);
    } else {
        Fail("could not convert token to LispString");
    }

    LispObject o3 = CreateFromToken(":foo");
    if (auto s2 = cast(LispKeyword) o3) {
        AssertEquals(s2.value, "foo");
    } else {
        Fail("could not convert token to LispSymbol");
    }

    LispObject o4 = CreateFromToken("#\\x");
    if (auto c1 = cast(LispCharacter) o4) {
        AssertEquals(c1.Repr(), "#\\x");
    } else {
        Fail("could not convert token to LispCharacter");
    }
}
