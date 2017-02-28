// types.d

abstract class LispObject {
    dstring Repr() { return "<undefined>"; }
}

class LispSymbol : LispObject {
    dstring value;
    override dstring Repr() { return value; }
}

abstract class LispList : LispObject {
}

class LispEmptyList : LispList {
    override dstring Repr() { return ""; }
}

class LispPair : LispList {
    LispObject head;
    LispObject tail;
    override dstring Repr() {
        // FIXME
        return "(" ~ head.Repr() ~ " . " ~ tail.Repr() ~ ")";
    }
}

