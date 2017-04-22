// test_tools.d

import interpreter;
import parser;
import test_parser;
import tools;
import tools_test;
import types;

unittest {
    AssertEquals(EscapeString("hello"d), `"hello"`d);
    AssertEquals(EscapeString("a\nb"d), `"a\nb"`d);
}

// test UnescapeString()
unittest {
    AssertEquals(UnescapeString(`"abc"`), "abc");
    AssertEquals(UnescapeString(`"foo\nbar"`), "foo\nbar");
    AssertEquals(UnescapeString(`"!\u0062!"`), "!b!");
    AssertEquals(UnescapeString(`"!\u042F!"`), "!Я!");
    AssertEquals(UnescapeString(`"!Я!"`), "!Я!");
    AssertEquals(UnescapeString(`"!\U0001F603!"`), "!😃!");
    AssertEquals(UnescapeString(`"a\x62c"`), "abc");
}

// test WrapExprsInDo()
unittest {
    auto intp = new Interpreter();

    // multiple expressions get wrapped in a DO
    auto results = intp.EvalString("3 4 5");
    AssertEquals(results.length, 3);
    auto expr = WrapExprsInDo(results);
    AssertEquals(expr.Repr(), "(do 3 4 5)");

    // a single expression doesn't get wrapped in a DO
    expr = WrapExprsInDo([new LispSymbol("x")]);
    AssertEquals(expr.Repr(), "x");
}

// test FindKeywordLiterals()
unittest {
    ParserResult pr = tokenize_and_parse("3");
    auto keywords = cast(LispObject[]) FindKeywordLiterals(pr.result);
    AssertEquals(keywords, []);

    pr = tokenize_and_parse("(f 1 :foo 2)");
    keywords = cast(LispObject[]) FindKeywordLiterals(pr.result);
    AssertEquals(keywords, [new LispKeyword("foo")]);

    pr = tokenize_and_parse("(f 1 :foo ':bar (g :baz 4))");
    keywords = cast(LispObject[]) FindKeywordLiterals(pr.result);
    AssertEquals(keywords, [new LispKeyword("foo")]);
}
