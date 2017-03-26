// tokenizer.d

import std.format;
import std.uni;
import errors;

// NOTE: The tokenizer needs to process the input text as an array of dchars;
// treating it as an array of bytes would not play well with character
// literals, among other things.

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
            if (token == '\\') {
                // a backslash should always be followed by at least one
                // character
                current_token ~= text[i..i+2];
                i++;
                continue;
            }
            if (token == '"') {
                // end of string reached
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
        } else if (current_token == "" && token == '#') {
            // #-codes
            if (text[i+1] == '\\') {
                // character literal
                dstring char_token = text[i..i+3];
                tokens ~= char_token;
                i += 2;  // skip past character literal
                // XXX can we have more than one character? e.g. CL and Scheme
                // allow constructs like #\space, etc. 
            } else {
                throw new UnknownCodeError(format("Unknown #-code: %s", tokens[i..i+10]));
            }
        } else {
            current_token ~= token;
        }
    }

    // if there's a token currently being built, then add it
    add_token_if_any();

    return tokens;
}
