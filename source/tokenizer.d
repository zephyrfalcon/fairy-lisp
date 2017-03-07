// tokenizer.d

import std.uni;

dstring[] tokenize(dstring text) {
    dstring[] tokens = [];
    dstring current_token = "";

    void add_token_if_any() {
        if (current_token.length > 0) {
            tokens ~= current_token;
            current_token = "";
        }
    }

    for (size_t i=0; i < text.length; i++) {
        dchar token = text[i];
        if (isWhite(token)) {
            add_token_if_any();
        } else if (token == '(') {
            add_token_if_any();
            tokens ~= "(";
        } else if (token == ')') {
            add_token_if_any();
            tokens ~= ")";
        } else if (token == '\'') {
            add_token_if_any();
            tokens ~= "'";
        } else {
            current_token ~= token;
        }
    }

    // if there's a token currently being built, then add it
    add_token_if_any();

    return tokens;
}
