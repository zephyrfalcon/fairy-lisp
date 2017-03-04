// tools.d

import types;

LispList FromArray(LispObject[] things) {
    LispList head = NIL();
    foreach (o; things) {
        LispPair new_pair = new LispPair(o, head);
        head = new_pair;
    }
    return head;
}

