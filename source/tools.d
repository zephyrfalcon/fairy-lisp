// tools.d

import std.array;
import std.conv;
import std.file;
import std.format;
import std.path;
import std.regex;
import std.stdio;
import errors;
import types;

// return the path of the executable.
string WhereAmI() {
    return dirName(absolutePath(thisExePath()));
}

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
    foreach (ref i, c; sinside) {
        if (c == '\\') {
            assert (sinside.length >= i+2, "incomplete escape code");
            switch (sinside[i+1]) {
                // there are more; see: 
                // https://dlang.org/spec/lex.html#StringLiteral
                case 'b': contents ~= "\b"; i++; break;
                case 'n': contents ~= "\n"; i++; break;
                case 'r': contents ~= "\r"; i++; break;
                case 't': contents ~= "\t"; i++; break;
                case '\'': contents ~= "\'"; i++; break;
                case 'u': {
                    assert (sinside.length >= i+6, "incomplete escape code");
                    // try next 4 characters (exactly 4)
                    dstring next4 = to!dstring(sinside[i+2..i+6]);
                    // all of them must be hex digits
                    if (matchFirst(next4, `^[0-9a-fA-F]{4}$`d).empty) 
                        throw new Exception("incomplete escape code");
                    // convert to the appropriate Unicode character
                    auto spec = singleSpec("%X");
                    dchar dc = unformatValue!dchar(next4, spec);
                    contents ~= dc;
                    i += 5;
                    break;
                }
                case 'U': {
                    // same as 'u', but 8 characters
                    assert (sinside.length >= i+10, "incomplete escape code");
                    // try next 4 characters (exactly 4)
                    dstring next8 = to!dstring(sinside[i+2..i+10]);
                    // all of them must be hex digits
                    if (matchFirst(next8, `^[0-9a-fA-F]{8}$`d).empty) 
                        throw new Exception("incomplete escape code");
                    // convert to the appropriate Unicode character
                    auto spec = singleSpec("%X");
                    dchar dc = unformatValue!dchar(next8, spec);
                    contents ~= dc;
                    i += 9;
                    break;
                }
                case 'x': {
                    dstring hexcode = sinside[i+1..i+3];
                    // figure out what character that is
                    // add to contents
                    i += 2;
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

LispObject WrapExprsInDo(LispObject[] exprs) {
    if (exprs.length > 1) {
        auto exprs_as_list = LispList.FromArray(exprs);
        auto p = new LispPair(new LispSymbol("do"), exprs_as_list);
        return p;
    } else return exprs[0];
}
