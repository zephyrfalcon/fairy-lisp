// tools.d

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

