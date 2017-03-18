// errors.d

import std.exception;

/*
template GenException(string name, string parent="Exception") {
    const char[] GenException =
    `class ` ~ name ~ ` : ` ~ parent ~ `
    {
        this(string msg="", string file = __FILE__, size_t line = __LINE__) {
            super(msg, file, line);
        }
    }`;
}
*/

//mixin(GenException!("ParserException"));
//mixin(GenException!("NoInputException", "ParserException"));
//mixin(GenException!("UnbalancedParenException", "ParserException"));
//mixin(GenException!("IncompleteExpressionException", "ParserException"));

class ParserException: Exception { mixin basicExceptionCtors; }
class NoInputException: ParserException { mixin basicExceptionCtors; }
class UnbalancedParenException: ParserException { mixin basicExceptionCtors; }
class IncompleteExpressionException: ParserException { mixin basicExceptionCtors; }

class EnvironmentKeyException: Exception { mixin basicExceptionCtors; }

class UnknownCodeError: Exception { mixin basicExceptionCtors; }

class StackError: Exception { mixin basicExceptionCtors; }
class StackOverflowError: StackError { mixin basicExceptionCtors; }
class StackUnderflowError: StackError { mixin basicExceptionCtors; }

class NotImplementedError: Exception { mixin basicExceptionCtors; }
class KeywordError: Exception { mixin basicExceptionCtors; }
class TypeError: Exception { mixin basicExceptionCtors; }

