// tools.d

import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.format;
import std.path;
import std.regex;
import std.stdio;
import std.string;
import errors;
import types;

// return the path of the executable.
string WhereAmI() {
    return dirName(absolutePath(thisExePath()));
}

// escape a string. this currently piggybacks D's string escaping, and
// whatever rules (if any) it uses for escaping Unicode characters, etc.
dstring EscapeString(dstring s) {
    auto writer = appender!dstring;
    formattedWrite(writer, "%(%s%)", [s]);
    return writer.data;
}

dstring UnescapeString(dstring s) {
    dstring contents = "";
    assert (s[0] == '"' && s[$-1] == '"' && s.length >= 2, 
            "string must be surrounded by quotes");
    dstring sinside = s[1..$-1];

    // parse exactly <numchars> hex characters from `sinside`, and convert them to a
    // dchar.
    dchar ParseHex(ulong pos, ulong numchars) {
        assert (sinside.length >= pos+2+numchars, "incomplete escape code");
        // try next <numchars> characters
        dstring next = to!dstring(sinside[pos+2..pos+2+numchars]);
        // all of them must be hex digits
        if (matchFirst(next, `^[0-9a-fA-F]+$`d).empty) 
            throw new Exception("incomplete escape code");
        // convert to the appropriate Unicode character
        auto spec = singleSpec("%X");
        dchar dc = unformatValue!dchar(next, spec);
        return dc;
    }

    foreach (ref i, c; sinside) {
        if (c == '\\') {
            assert (sinside.length >= i+2, "incomplete escape code");
            switch (sinside[i+1]) {
                // there are more; see: 
                // https://dlang.org/spec/lex.html#StringLiteral
                case 'b': contents ~= "\b"; i++; break;
                case 'f': contents ~= "\f"; i++; break;
                case 'n': contents ~= "\n"; i++; break;
                case 'r': contents ~= "\r"; i++; break;
                case 't': contents ~= "\t"; i++; break;
                case 'v': contents ~= "\v"; i++; break;
                case '\'': contents ~= "\'"; i++; break;
                case '"': contents ~= "\""; i++; break;
                case '\\': contents ~= "\\"; i++; break;
                case '?': contents ~= "?"; i++; break;
                case '0': contents ~= "\0"; i++; break;
                case 'u': {
                    dchar dc = ParseHex(i, 4);
                    contents ~= dc;
                    i += 5;
                    break;
                }
                case 'U': {
                    dchar dc = ParseHex(i, 8);
                    contents ~= dc;
                    i += 9;
                    break;
                }
                case 'x': {
                    dchar dc = ParseHex(i, 2);
                    contents ~= dc;
                    i += 3;
                    break;
                }
                default: throw new Exception("unknown escape code");
            }
        } else {
            contents ~= c;
        }
    }
    return contents;
}

dstring[] LispTypeListAsReprs(LispObject[] values) {
    dstring[] reprs = [];
    foreach (value; values) {
        reprs ~= value.Repr();
    }
    return reprs;
}

dstring[] GetListOfSymbols(LispObject[] values) {
    dstring[] names = [];
    foreach(value; values) {
        if (auto sym = cast(LispSymbol) value) {
            names ~= sym.value;
        } else 
            throw new TypeError("symbol expected");
    }
    return names;
}

// convert a list of names (as dstrings) to a list of LispSymbols
LispObject[] NamesAsSymbols(dstring[] names) {
    //LispObject[] symbols = map!(s => new LispSymbol(s))(names);  // doesn't work
    LispObject[] symbols = [];
    foreach(name; names) {
        symbols ~= LispSymbol.Get(name);
    }
    return symbols;
}

LispObject WrapExprsInDo(LispObject[] exprs) {
    if (exprs.length > 1) {
        auto exprs_as_list = LispList.FromArray(exprs);
        auto p = new LispPair(LispSymbol.Get("do"), exprs_as_list);
        return p;
    } else return exprs[0];
}

// returns true if x is a symbol with the given value.
bool IsSymbol(LispObject x, dstring value) {
    if (auto sym = cast(LispSymbol) x) {
        return sym.value == toLower(value);
    }
    return false;
}

bool TruthValue(LispObject x) {
    if (x is FALSE()) return false;
    return true;
}

// scan a Lisp expression (assumed to be a function call form) and return an
// array of all keyword literals found. does not evaluate anything. only
// keyword *literals* are considered a match, not any expression that would
// evaluate to a keyword object.
LispKeyword[] FindKeywordLiterals(LispObject expr) {
    LispKeyword[] keywords = [];
    if (auto list = cast(LispList) expr) {
        try {
            LispObject[] elems = list.ToArray();
            foreach(elem; elems) {
                if (auto kw = cast(LispKeyword) elem) {
                    keywords ~= kw;
                }
            }
        } catch (ImproperListError e) {
            return []; // improper lists are not considered
        }
        return keywords;
    } else
        return [];
}

bool IsImproperList(LispObject x) {
    if (auto list = cast(LispPair) x) {
        LispPair here = list;
        while (true) {
            if (auto next = cast(LispPair) here.tail) {
                here = next;
            }
            else if (here.tail is NIL())
                return true;  // reached end of list, it's proper
            else {
                // neither a LispPair nor a LispEmptyList, so this is an
                // improper list!
                return true;
            }
        }
    }
    else return false;  // it's not a list at all
}
