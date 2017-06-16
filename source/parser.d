// parser.d

import std.conv;
import std.regex;
import std.stdio;
import errors;
import tools;
import types;

struct ParserResult {
    LispObject result;
    dstring[] rest_tokens;
}

ParserResult parse(dstring[] tokens) {
    if (tokens.length == 0)
        throw new NoInputException("no input");
    if (tokens[0] == "(") {
        LispObject[] elems = [];
        tokens = tokens[1..$];
        while (true) {
            if (tokens.length == 0) 
                throw new UnbalancedParenException("missing closing parenthesis");
            if (tokens[0] == ")") {
                // matching closing parenthesis reached
                // check if this is an improper list
                // check if "." is in any other spot; that's an error
                foreach (i, x; elems) {
                    if (i != elems.length-2) {
                        if (x == LispSymbol.Get("."))
                            throw new ParserError("incorrect use of '.'");
                    }
                }
                LispList list;
                if (elems.length > 2 && elems[$-2] == LispSymbol.Get(".")) {
                    list = LispList.MakeImproperList(elems[0..$-2], elems[$-1]);
                } else {
                    list = LispList.FromArray(elems);
                }
                return ParserResult(list, tokens[1..$]);
            } else {
                ParserResult stuff = parse(tokens);
                elems ~= stuff.result;
                tokens = stuff.rest_tokens;
            }
        }
    } else if (tokens[0] == ")") {
        throw new UnbalancedParenException("unbalanced parenthesis");
    } else if (tokens[0] == "'" || tokens[0] == "," || tokens[0] == "`" ||
               tokens[0] == ",@") {
        if (tokens.length <= 1)
            throw new IncompleteExpressionException("incomplete expression");
        ParserResult pr = parse(tokens[1..$]);
        dstring sym = "";
        switch (tokens[0]) {
            case "'": sym = "quote"; break;
            case ",": sym = "unquote"; break;
            case "`": sym = "quasiquote"; break;
            case ",@": sym = "unquote-splicing"; break;
            default:
                throw new Exception("not a quote");
        }
        LispObject expr = new LispPair(LispSymbol.Get(sym), 
                          new LispPair(pr.result, NIL()));
        return ParserResult(expr, pr.rest_tokens);
    } else {
        // this is an atomic object; return it
        if (tokens[0] == ".")
            throw new ParserError("invalid use of '.'");
        return ParserResult(CreateFromToken(tokens[0]), tokens[1..$]);
    }
}

LispObject CreateFromToken(dstring token) {
    if (!(matchFirst(token, `^-?\d+$`d).empty)) {
        return new LispInteger(to!int(token));
    }
    if (!(matchFirst(token, `^-?\d+\.\d+$`d).empty)) {
        return new LispFloat(to!real(token));
    }
    if (!(matchFirst(token, `^".*"$`d).empty)) {
        return new LispString(UnescapeString(token));
    }
    if (!(matchFirst(token, `^#\\.+$`d).empty)) {
        return new LispCharacter(token[2]);  // *must* be a dchar
    }
    if (!(matchFirst(token, `^:.+$`d).empty)) {
        return new LispKeyword(token[1..$]);
    }
    return LispSymbol.Get(token); // default
}

