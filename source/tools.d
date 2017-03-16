// tools.d

import std.array;
import std.file;
import std.format;
import std.path;
import std.stdio;
import types;

LispList FromArray(LispObject[] things) {
    LispList head = NIL();
    size_t len = things.length;
    for (size_t i=0; i < len; i++) {
        LispObject o = things[len-1-i];
        LispPair new_pair = new LispPair(o, head);
        head = new_pair;
    }
    return head;
}

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
