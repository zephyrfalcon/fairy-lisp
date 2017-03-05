// errors.d

template GenException(string name, string parent="Exception") {
    const char[] GenException =
    `class ` ~ name ~ ` : ` ~ parent ~ `
    {
        this(string msg="", string file = __FILE__, size_t line = __LINE__) {
            super(msg, file, line);
        }
    }`;
}

mixin(GenException!("ParserException"));
mixin(GenException!("NoInputException", "ParserException"));
mixin(GenException!("UnbalancedParenException", "ParserException"));
mixin(GenException!("IncompleteExpressionException", "ParserException"));
