// types.d

import std.array;
import std.conv;
import std.stdio;
import std.string;
import errors;
import interpreter;
import tools;

abstract class LispObject {
    LispType[dstring] _types;
    dstring Repr() { return "<undefined>"; }
    override bool opEquals(Object o) { 
        return false; 
        // FIXME: add comparison rules for objects of different types?
    }
    bool IsTrue() { return true; }
    dstring TypeName() { throw new NotImplementedError("abstract type"); }
    LispType GetType() {
        return this._types[this.TypeName()];
    }
}

class LispType : LispObject {
    dstring name;
    LispType parent;
    this(dstring name) {
        this.name = name;
    }
    this(dstring name, LispType parent) {
        this.name = name;
        this.parent = parent;
    }
    override dstring Repr() { return format("#<type:%s>"d, this.name); }
    override dstring TypeName() { return "type"; }
}

class LispSymbol : LispObject {
    dstring value;
    this(dstring s) { this.value = toLower(s); }
    override dstring Repr() { return value; }
    override bool opEquals(Object o) {
        if (auto other = cast(LispSymbol) o) {
            return this.value == other.value;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "symbol"; }
}

class LispInteger : LispObject {
    int value;
    this(int x) { this.value = x; }
    override dstring Repr() { return to!dstring(this.value); }
    override bool opEquals(Object o) {
        if (auto other = cast(LispInteger) o) {
            return this.value == other.value;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "integer"; }
}

class LispString : LispObject {
    dstring value;
    this(dstring s) { this.value = s; }
    override dstring Repr() { return EscapeString(this.value); } 
    override bool opEquals(Object o) {
        if (auto other = cast(LispString) o) {
            return this.value == other.value;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "string"; }
}

class LispCharacter : LispObject {
    dchar value;
    this(dchar c) { this.value = c; }
    override dstring Repr() { return "#\\"d ~ this.value; }
    override bool opEquals(Object o) {
        if (auto other = cast(LispCharacter) o) {
            return this.value == other.value;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "char"; }
}

class LispKeyword : LispObject {
    dstring value;
    this(dstring s) { this.value = s; }  // XXX what of leading ":"?
    override dstring Repr() { return ":"d ~ this.value; }
    override bool opEquals(Object o) {
        if (auto other = cast(LispKeyword) o) {
            return this.value == other.value;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "keyword"; }
}

class LispBoolean : LispObject {
    bool value;
    this(bool value) { this.value = value; }
    override dstring Repr() { return this.value ? "true" : "false"; }
    override bool opEquals(Object o) {
        if (auto other = cast(LispBoolean) o) {
            return this.value == other.value;
        } else return super.opEquals(o);
    }
    override bool IsTrue() { return this.value; }
    override dstring TypeName() { return "boolean"; }
}

abstract class LispList : LispObject {
    LispList Reverse() { throw new Exception("abstract method"); };
    LispObject[] ToArray() { throw new Exception("abstract method"); }
    override dstring TypeName() { return "list"; }

    static LispList FromArray(LispObject[] things) {
        LispList head = NIL();
        size_t len = things.length;
        for (size_t i=0; i < len; i++) {
            LispObject o = things[len-1-i];
            LispPair new_pair = new LispPair(o, head);
            head = new_pair;
        }
        return head;
    }
}

class LispEmptyList : LispList {
    override dstring Repr() { return "()"; }
    override LispList Reverse() { return NIL(); }
    override LispObject[] ToArray() { LispObject[] elems = []; return elems; }
    override bool opEquals(Object o) {
        if (auto other = cast(LispEmptyList) o) {
            return true;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "nil"; }
}

class LispPair : LispList {
    LispObject head;
    LispObject tail;

    this(LispObject head, LispObject tail) {
        this.head = head;
        this.tail = tail;
    }

    override bool opEquals(Object o) {
        if (auto other = cast(LispPair) o) {
            if (this.head != other.head) return false;
            return this.tail == other.tail;
        } else return super.opEquals(o);
    }

    override dstring Repr() {
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
                throw new ImproperListError("cannot reverse improper list");
            }
        }
        return acc;
    }

    override LispObject[] ToArray() {
        LispObject[] elems = [];
        LispPair p = this;
        while (true) {
            elems ~= p.head;
            if (auto next_pair = cast(LispPair) p.tail) {
                p = next_pair;
            } else if (auto empty = cast(LispEmptyList) p.tail) {
                // end of list reached
                return elems;
            } else {
                throw new ImproperListError("cannot convert improper list to array");
            }
        }
    }

    override dstring TypeName() { return "pair"; }
}

struct FunctionArgs {
    LispObject[] args;
    LispObject[] rest_args;
    LispObject[dstring] keyword_args;

    static FunctionArgs Parse(int arity, LispObject[] args) {
        FunctionArgs fa = FunctionArgs();
        for (int i=0; i < args.length; i++) {
            if (auto kw = cast(LispKeyword) args[i]) {
                // a keyword always must be followed by value, so it cannot be the
                // last argument in the list
                if (i == args.length+1)
                    throw new KeywordError("keyword must have a value");
                // keyword should not exist already
                LispObject *p = (kw.value in fa.keyword_args);
                if (p is null) {
                    fa.keyword_args[kw.value] = args[i+1];
                    i++;
                } else
                    throw new KeywordError(format("keyword already exists: %s", 
                                           kw.Repr()));
            } else if (fa.args.length >= arity) {
                fa.rest_args ~= args[i];
            } else {
                fa.args ~= args[i];
            }
        }
        return fa;
    }

    // get all "regular" (non-keyword) args 
    LispObject[] GetAllArgs() {
        LispObject[] all_args = this.args;  // seems to be a shallow copy
        all_args ~= this.rest_args;  // does not affect this.args
        return all_args;
    }
}

alias BuiltinFunctionSig = 
  LispObject function(Interpreter, LispEnvironment, FunctionArgs);
alias SpecialFormSig =
  LispObject function(Interpreter, LispEnvironment, LispObject[]);

abstract class LispFunction : LispObject {
    dstring name;
    int arity;
    override dstring TypeName() { return "function"; }
}

class LispBuiltinFunction : LispFunction {
    BuiltinFunctionSig f;

    this(dstring name, BuiltinFunctionSig f, int arity) {
        this.name = name;
        this.f = f;
        this.arity = arity;
    }

    override dstring Repr() {
        return format("#<%s>"d, this.name);
    }
    override bool opEquals(Object o) {
        if (auto other = cast(LispBuiltinFunction) o) {
            return this.name == other.name && this.f == other.f 
                && this.arity == other.arity;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "bfunc"; }
}

class LispUserDefinedFunction : LispFunction {
    dstring[] argnames;
    LispObject[] fbody;  // a list of expressions
    LispEnvironment env;  // environment it was created in

    this(dstring[] argnames, LispObject[] fbody, LispEnvironment env, 
         dstring name="") {
        this.argnames = argnames;
        this.fbody = fbody;
        this.env = env;
        this.name = name;
        this.arity = cast(int) argnames.length;
    }

    override dstring Repr() {
        return format("#<%s>"d, this.name == "" ? "user-defined function" : this.name);
    }
    override bool opEquals(Object o) {
        if (auto other = cast(LispUserDefinedFunction) o) {
            return this.name == other.name 
                && this.arity == other.arity && this.fbody == other.fbody
                && this.argnames == other.argnames && this.env == other.env;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "ufunc"; }
}

struct EnvFindResult {
    LispEnvironment env;
    LispObject value;
}

class LispEnvironment : LispObject {
    LispEnvironment parent;
    LispObject[dstring] names;  // NOTE: initializes to null

    this() { }
    this(LispEnvironment parent) {
        this.parent = parent;
    }

    void Set(dstring name, LispObject value) {
        this.names[name] = value;
    }

    // look for the given name in this environment; if not found, look
    // recursively in its parent. if still not found anywhere, raise an
    // exception; otherwise return an EnvFindResult containing the environment
    // where it was found, and the associated value.
    EnvFindResult Find(dstring name) {
        auto value = (name in this.names);
        if (value is null) {
            if (this.parent is null) {
                throw new EnvironmentKeyException(format("key not found: %s",
                                                  name));
            } else {
                return this.parent.Find(name);
            }
        } else {
            return EnvFindResult(this, *value);
        }
    }

    LispObject Get(dstring name) {
        auto efr = this.Find(name);
        return efr.value;
    }
    
    LispObject GetLocal(dstring name) {
        auto value = (name in this.names);
        if (value is null) {
            throw new EnvironmentKeyException(format("key not found: %s", name));
        } else {
            return *value;
        }
    }

    // update a value associated with the given name, i.e. find it in the
    // environment *or a parent*, then update the value in *that environment*.
    // raises an error if the name was not found.
    void Update(dstring name, LispObject value) {
        auto efr = this.Find(name);  // will raise error if not found
        efr.env.Set(name, value);
    }

    void DeleteLocal(dstring name) {
        this.names.remove(name);
    }

    void Delete(dstring name) {
        try {
            auto efr = this.Find(name);
            efr.env.DeleteLocal(name);
        } catch (EnvironmentKeyException e) {
            // key does not exist; don't do anything
        }
    }

    dstring[] GetNames() {
        return this.names.keys;  // in no particular order
    }

    override dstring TypeName() { return "env"; }
}

class LispDictionary : LispObject {
    LispObject[LispObject] values;
    override dstring Repr() { return "#<dict>"; } // FIXME
    override bool opEquals(Object o) {
        if (auto other = cast(LispDictionary) o) {
            return this.values == other.values;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "dict"; }
}

/* "singletons", sort of kind of */

// this is one way to make sure we always use the same object... through a
// function. NOTE: never create these objects directly.

LispEmptyList NIL() {
    static LispEmptyList e;
    if (!e) e = new LispEmptyList();
    return e;
}

LispBoolean TRUE() {
    static LispBoolean _true;
    if (!_true) _true = new LispBoolean(true);
    return _true;
}
LispBoolean FALSE() {
    static LispBoolean _false;
    if (!_false) _false = new LispBoolean(false);
    return _false;
}

