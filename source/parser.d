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
        LispList list = NIL();
        tokens = tokens[1..$];
        while (true) {
            if (tokens.length == 0) 
                throw new UnbalancedParenException("missing closing parenthesis");
            if (tokens[0] == ")") {
                // matching closing parenthesis reached
                return ParserResult(list.Reverse(), tokens[1..$]);
            } else {
                ParserResult stuff = parse(tokens);
                list = new LispPair(stuff.result, list);
                tokens = stuff.rest_tokens;
            }
        }
    } else if (tokens[0] == ")") {
        throw new UnbalancedParenException("unbalanced parenthesis");
    } else if (tokens[0] == "'") {
        if (tokens.length <= 1)
            throw new IncompleteExpressionException("incomplete expression");
        ParserResult pr = parse(tokens[1..$]);
        LispObject expr = new LispPair(LispSymbol.Get("quote"), 
                          new LispPair(pr.result, NIL()));
        return ParserResult(expr, pr.rest_tokens);
    } else {
        // this is an atomic object; return it
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

