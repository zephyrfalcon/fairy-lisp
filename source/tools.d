// tools.d

import std.array;
import std.file;
import std.format;
import std.path;
import std.stdio;
import types;

// return the path of the executable.
string WhereAmI() {
    return dirName(absolutePath(thisExePath()));
}

string EscapeString(string s) {
    auto writer = appender!string;
    formattedWrite(writer, "%(%s%)", [s]);
    return writer.data;
}
dstring EscapeString(dstring s) {
    auto writer = appender!dstring;
    formattedWrite(writer, "%(%s%)", [s]);
    return writer.data;
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
