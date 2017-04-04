// tools.d

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

LispObject WrapExprsInDo(LispObject[] exprs) {
    if (exprs.length > 1) {
        auto exprs_as_list = LispList.FromArray(exprs);
        auto p = new LispPair(new LispSymbol("do"), exprs_as_list);
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
