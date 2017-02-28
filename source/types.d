// types.d

import std.array;

abstract class LispObject {
    dstring Repr() { return "<undefined>"; }
}

class LispSymbol : LispObject {
    dstring value;
    override dstring Repr() { return value; }
    this(dstring s) { this.value = s; }
}

abstract class LispList : LispObject {
}

class LispEmptyList : LispList {
    override dstring Repr() { return "()"; }
}

class LispPair : LispList {
    LispObject head;
    LispObject tail;

    this(LispObject head, LispObject tail) {
        this.head = head;
        this.tail = tail;
    }

    override dstring Repr() {
        //return "(" ~ head.Repr() ~ " . " ~ tail.Repr() ~ ")";
        LispPair p = this;
        dstring[] elems = [];
        while (1) {
            elems ~= p.head.Repr();
            if (auto p2 = cast(LispPair)(p.tail)) {
                // tail is also a pair; continue
                p = p2;
            } else if (cast(LispEmptyList)(p.tail)) {
                // end of proper list has been reached; return repr
                return "(" ~ join(elems, " ") ~ ")";
            } else {
                // improper list
                dstring s = join(elems, " ");
                s = s ~ " . " ~ p.tail.Repr();
                return "(" ~ s ~ ")";
            }
        }
    }
}

