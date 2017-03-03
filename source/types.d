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
    LispList Reverse() { throw new Exception("abstract method"); };
}

class LispEmptyList : LispList {
    override dstring Repr() { return "()"; }
    override LispList Reverse() { return NIL(); }
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

    override LispList Reverse() {
        LispList acc = NIL(); 
        LispObject p = this;
        while (true) {
            if (auto p2 = cast(LispPair) p) {
                acc = new LispPair(p2.head, acc);
                p = p2.tail;
            } else if (auto e = cast(LispEmptyList) p) {
                break;  // all done
            } else {
                throw new Exception("cannot reverse improper list");
            }
        }
        return acc;
    }
}

/* "constants" */

/*
const LispEmptyList _EMPTY_LIST = new LispEmptyList();

LispEmptyList NIL() { return cast(LispEmptyList) _EMPTY_LIST; }
*/

// this is one way to make sure we always use the same object... through a
// function. 

LispEmptyList NIL() {
    static LispEmptyList e;
    if (!e) e = new LispEmptyList();
    return e;
}
