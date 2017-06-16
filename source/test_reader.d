// test_reader.d

import std.file;
import std.path;
import std.stdio;
import errors;
import reader;
import tools;
import tools_test;
import types;

// test StringReader
unittest {
    auto sr = new StringReader("1 (2 3) 4");
    LispObject[] exprs = [];
    while (true) {
        try {
            LispObject expr = sr.Read();
            exprs ~= expr;
        } catch (errors.NoInputError e) {
            break;
        }
    }
    AssertEquals(exprs.length, 3);
    AssertEquals(exprs[0].Repr(), "1");
    AssertEquals(exprs[1].Repr(), "(2 3)");

    // TODO: test unbalanced parentheses
}

// test FileReader
unittest {
    string path = buildPath(WhereAmI(), "source", "tests", "etc", "1.sl");
    LispObject[] exprs = [];
    auto fr = new FileReader(path);
    while (true) {
        try {
            LispObject expr = fr.Read();
            exprs ~= expr;
        } catch (NoInputError e) {
            break;
        }
    }

    AssertEquals(exprs.length, 4);
    AssertEquals(exprs[3].Repr(), "33");
    AssertEquals(exprs[2].Repr(), "(baz (quux 4))");

    // --- incomplete expressions

    bool detected = false;  // did we detect the unbalanced paren?
    path = buildPath(WhereAmI(), "source", "tests", "etc", "2.sl");
    exprs = [];
    fr = new FileReader(path);
    while (true) {
        try {
            LispObject expr = fr.Read();
        } catch (NoInputError e) {
            break;
        } catch (IncompleteExpressionError e) {
            detected = true; break;
        }
    }
    AssertEquals(detected, true);

    // --- quoting

    path = buildPath(WhereAmI(), "source", "tests", "etc", "3.sl");
    exprs = [];
    fr = new FileReader(path);
    LispObject expr = fr.Read();
    AssertEquals(expr.Repr(), "(quote (1 2))");
}

