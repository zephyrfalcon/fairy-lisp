// test_parser.d

import parser;
import tokenizer;

ParserResult tokenize_and_parse(dstring text) {
    auto tokens = tokenize(text);
    auto pr = parse(tokens);
    return pr;
}

unittest {
}

