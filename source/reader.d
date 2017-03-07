// reader.d

import std.conv;
import std.stdio;
//
import errors;
import parser;
import tokenizer;
import types;

/*
 * A Reader is an object that reads Lisp expressions from a stream (usually a
 * string or a file). The main method is Read(), which returns the next
 * expression found (if any, otherwise nil), and an error code if something
 * went wrong.
 *
 * Like a file object, a Reader keeps track of what parts of a stream have not
 * been processed yet. In the case of FileReader, it will read from its
 * associated file as necessary until enough tokens have been scanned to form
 * a complete expression.
 *
 * If an incomplete expression has been read, but there is no more input, then
 * this is of course an error, and IncompleteExpressionException will be
 * raised.
 *
 * If a Reader has no more input left, either from tokens already read or from
 * its associated file, then it will throw NoInputException. This is usually not
 * an error, but simply indicates that there is nothing left to read.
 *
 * It is probably best to read files whole as one big string, then process
 * them via StringReader, unless we have no other choice for some reason (e.g.
 * in the case of stdin).
 *
 */

abstract class Reader {
}

class FileReader : Reader {
    File file;
    dstring[] tokens_read = [];

    this(File file) { 
        this.file = file;
    }
    this(string filename) {
        this.file = File(filename, "r");
    }

    LispObject Read() {
        while (true) {
            // first, try to read expression from tokens we already have
            try {
                ParserResult pr = parse(this.tokens_read);
                // no error occurred
                this.tokens_read = pr.rest_tokens;
                return pr.result;
            } catch (Exception error) {
                // that didn't work. let's read another line
                string line_raw = this.file.readln();
                if (line_raw is null) { // EOF
                    if (this.tokens_read.length > 0)
                        throw new IncompleteExpressionException("incomplete expression");
                    throw new NoInputException("no input");
                }
                // no EOF; let's see what we have
                dstring line = to!dstring(line_raw);
                auto tokens = tokenize(line);
                this.tokens_read ~= tokens;
                // go for another round
            }
        }
    }
}

class StringReader : Reader {
    dstring[] tokens = [];

    this(dstring s) {
        this.tokens = tokenize(s);
    }

    LispObject Read() {
        ParserResult pr = parse(this.tokens);
        this.tokens = pr.rest_tokens;
        return pr.result;
    }
}

