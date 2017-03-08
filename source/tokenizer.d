// tokenizer.d

import std.uni;

dstring[] tokenize(dstring text) {
    dstring[] tokens = [];
    dstring current_token = "";
    bool in_comment = false, in_string = false;

    void add_token_if_any() {
        if (current_token.length > 0) {
            tokens ~= current_token;
            current_token = "";
        }
    }

    for (size_t i=0; i < text.length; i++) {
        dchar token = text[i];
        if (in_comment) {
            if (token == '\n')  // newline ends comment
                in_comment = false;
        } else if (in_string) {
            if (token == '"') {
                current_token ~= token;
                tokens ~= current_token;
                current_token = "";
                in_string = false;
            } else {
                current_token ~= token;
            }
        } else if (isWhite(token)) {
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
        } else if (token == ';') {
            in_comment = true;
            add_token_if_any();
        } else if (token == '"') {
            in_string = true;
            current_token ~= token;  // is this correct? :-/
        } else {
            current_token ~= token;
        }
        // TODO: #-codes
    }

    // if there's a token currently being built, then add it
    add_token_if_any();

    return tokens;
}
