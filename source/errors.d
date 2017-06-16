// errors.d

import std.exception;
import std.format;
import types;

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

//mixin(GenException!("ParserError"));
//mixin(GenException!("NoInputException", "ParserError"));
//mixin(GenException!("UnbalancedParenException", "ParserError"));
//mixin(GenException!("IncompleteExpressionException", "ParserError"));

class ParserError: Exception { mixin basicExceptionCtors; }

class RecoverableParserError: ParserError { mixin basicExceptionCtors; }
// the following exceptions are recoverable parser errors; if there is no
// input, or the input is incomplete (but otherwise correct), we can fix the
// problem by asking for more input (if possible).
class IncompleteExpressionError: RecoverableParserError { mixin basicExceptionCtors; }
class NoInputError: RecoverableParserError { mixin basicExceptionCtors; }

// there are also unrecoverable parser errors:
// raised when we run into a CLOSING parenthesis that has no match
class UnbalancedParenError: ParserError { mixin basicExceptionCtors; }
// reserved for other problems, like '.' in the wrong place
class SyntaxError: ParserError { mixin basicExceptionCtors; }
// there is no input left

class EnvironmentKeyException: Exception { mixin basicExceptionCtors; }

class UnknownCodeError: Exception { mixin basicExceptionCtors; }

class StackError: Exception { mixin basicExceptionCtors; }
class StackOverflowError: StackError { mixin basicExceptionCtors; }
class StackUnderflowError: StackError { mixin basicExceptionCtors; }

class NotImplementedError: Exception { mixin basicExceptionCtors; }
class KeywordError: Exception { mixin basicExceptionCtors; }
class TypeError: Exception { mixin basicExceptionCtors; }
class NameError: Exception { mixin basicExceptionCtors; }

class ImproperListError: Exception { mixin basicExceptionCtors; }
class KeyError: Exception { mixin basicExceptionCtors; }

import std.conv;
class XTypeError: Exception { 
    mixin basicExceptionCtors; 
    this(dstring culprit, dstring expected, LispObject actual) {
        dstring msg = format("%s: %s expected; got %s instead (%s)"d,
                        culprit, expected, actual.Repr(), actual.GetType().name);
        super(to!string(msg));
    }
}

