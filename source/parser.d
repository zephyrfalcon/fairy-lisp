// parser.d

import types;

struct ParserResult {
    LispObject result;
    dstring[] rest_tokens;
}

ParserResult parse(dstring[] tokens) {
    assert(tokens.length > 0);
    if (tokens[0] == "(") {
        LispList list = cast(LispEmptyList) EMPTY_LIST;
        tokens = tokens[1..$];
        while (true) {
            if (tokens.length == 0) 
                throw new Exception("missing closing parenthesis");
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
        throw new Exception("unbalanced parenthesis");
    } else {
        // this is an atomic object; return it
        return ParserResult(CreateFromToken(tokens[0]), tokens[1..$]);
    }
}

LispObject CreateFromToken(dstring s) {
    return new LispSymbol(s); // default
}

