// parser.d

import std.conv;
import std.regex;
import errors;
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
        LispObject expr = new LispPair(new LispSymbol("quote"), 
                          new LispPair(pr.result, NIL()));
        return ParserResult(expr, pr.rest_tokens);
    } else {
        // this is an atomic object; return it
        return ParserResult(CreateFromToken(tokens[0]), tokens[1..$]);
    }
}

//const auto re_integer = regex(`^-?\d+$`d);

LispObject CreateFromToken(dstring token) {
    auto re_integer = regex(`^-?\d+$`d);
    auto m = matchFirst(token, re_integer);
    if (!m.empty) {
        return new LispInteger(to!int(token));
    }
    return new LispSymbol(token); // default
}

