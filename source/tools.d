// tools.d

import std.file;
import std.path;
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
