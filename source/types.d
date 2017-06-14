// types.d

import std.algorithm : canFind;
import std.algorithm.sorting;
import std.array;
import std.conv;
import std.stdio;
import std.string;
import errors;
import interpreter;
import tools;

abstract class LispObject {
    static LispType[dstring] _types;
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
    dstring ToString() { return this.Repr(); }
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
    override bool opEquals(Object o) {
        if (auto other = cast(LispType) o) {
            return this.name == other.name && this.parent == other.parent;
        } else return super.opEquals(o);
    }
    bool HasParentType(LispType other) {
        if (this.parent is null) return false;
        if (this.parent is other) return true;  // same type counts as false
        if (this is this.parent) return false;  // type is its own parent
        return this.parent.HasParentType(other);
    }
}

class LispSymbol : LispObject {
    static LispSymbol[dstring] _cache;
    dstring value;

    this(dstring s) { this.value = toLower(s); }

    // NOTE: This is the main way to create/get new symbols! Avoid using 'new
    // LispSymbol'.
    static LispSymbol Get(dstring name) {
        name = toLower(name);
        auto p = (name in LispSymbol._cache);
        if (p is null) {
            LispSymbol sym = new LispSymbol(name);  // sic
            LispSymbol._cache[name] = sym;
            return sym;
        } else
            return *p;
    }

    static bool Exists(dstring name) {
        auto p = (name in LispSymbol._cache);
        return (p !is null);
    }

    static LispSymbol GenUnique() {
        static ulong counter = 0;
        while (true) {
            counter++;
            dstring name = format("!g!#%s"d, counter);
            if (LispSymbol.Exists(name)) {
                counter++;
            } else {
                return LispSymbol.Get(name);
            }
        }
    }

    override dstring Repr() { return value; }
    override bool opEquals(Object o) {
        if (auto other = cast(LispSymbol) o) {
            return this.value == other.value;
        } else return super.opEquals(o);
    }
    override size_t toHash() { return value.length; } // FIXME
    override dstring TypeName() { return "symbol"; }
}

abstract class LispNumber : LispObject {
    override dstring TypeName() { return "number"; }
    // TODO: needs special number comparison?
    real AsFloat() { throw new NotImplementedError("AsFloat"); }
}

class LispInteger : LispNumber {
    int value;
    this(int x) { this.value = x; }
    override dstring Repr() { return to!dstring(this.value); }
    override bool opEquals(Object o) {
        if (auto other = cast(LispInteger) o) {
            return this.value == other.value;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "integer"; }
    override real AsFloat() { return this.value * 1.0; }
}

class LispFloat : LispNumber {
    real value;
    this(real x) { this.value = x; }
    override dstring Repr() { 
        dstring repr = format("%.20f"d, this.value);
        while (endsWith(repr, "0"))
            repr = repr[0..$-1];
        if (endsWith(repr, "."))
            repr ~= "0";
        return repr;
    }
    override bool opEquals(Object o) {
        if (auto other = cast(LispFloat) o) {
            return this.value == other.value;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "float"; }
    override real AsFloat() { return this.value; }
}

class LispString : LispObject {
    dstring value;
    this(dstring s) { this.value = s; }
    override dstring Repr() { return EscapeString(this.value); } 
    override dstring ToString() { return this.value; }
    override bool opEquals(Object o) {
        if (auto other = cast(LispString) o) {
            return this.value == other.value;
        } else return super.opEquals(o);
    }
    override size_t toHash() { return value.length; } // FIXME
    override dstring TypeName() { return "string"; }
}

class LispCharacter : LispObject {
    dchar value;
    this(dchar c) { this.value = c; }
    override dstring Repr() { return "#\\"d ~ this.value; }
    override dstring ToString() { return format("%c"d, this.value); }
    override bool opEquals(Object o) {
        if (auto other = cast(LispCharacter) o) {
            return this.value == other.value;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "char"; }
}

class LispKeyword : LispObject {
    dstring value;
    this(dstring s) { this.value = s; }  // is not supposed to have leading ':'
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
    int Length() { return 0; }

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

    static LispList MakeImproperList(LispObject[] elems, LispObject tail) {
        LispList head = NIL();
        for (size_t i=0; i < elems.length; i++) {
            LispObject o = elems[$-1-i];
            LispPair new_pair = new LispPair(o, head);
            if (i == 0) new_pair.tail = tail;
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
    override int Length() { return 0; }
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

    override int Length() {
        int length = 1;
        LispPair current = this;
        while (current.tail !is NIL()) {
            if (auto tail = cast(LispPair) current.tail) {
                length++;
                current = tail;
            } else
                throw new ImproperListError("cannot take length of improper list");
        }
        return length;
    }
}

struct FunctionArgs {
    LispObject[] args;
    LispObject[] rest_args;
    LispObject[dstring] keyword_args;

    static FunctionArgs Parse(int arity, LispObject[] args, LispKeyword[] kwlit) {
        FunctionArgs fa = FunctionArgs();

        void AddArg(int i) {
            if (fa.args.length >= arity) {
                fa.rest_args ~= args[i];
            } else {
                fa.args ~= args[i];
            }
        }

        for (int i=0; i < args.length; i++) {
            if (auto kw = cast(LispKeyword) args[i]) {
                // a keyword that is not in the list of keyword literals that
                // we found in the function call, is considered a regular
                // object rather than a keyword argument!
                if (!(kwlit.canFind(kw))) {
                    AddArg(i);
                    continue;
                }
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
            } else
                AddArg(i);
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

class LispMacro : LispUserDefinedFunction {
    this(dstring[] argnames, LispObject[] fbody, LispEnvironment env, 
         dstring name="") {
        super(argnames, fbody, env, name);
    }
    override dstring Repr() {
        return format("#<%s>"d, this.name == "" ? "macro" : this.name);
    }
    override bool opEquals(Object o) {
        if (auto other = cast(LispMacro) o) {
            return this.name == other.name 
                && this.arity == other.arity && this.fbody == other.fbody
                && this.argnames == other.argnames && this.env == other.env;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "macro"; }
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

    dstring[] GetLocalNames() {
        dstring[] localnames = this.names.keys;  // in no particular order
        localnames.sort();
        return localnames;
    }

    dstring[] GetNames() {
        bool[dstring] all_names;
        LispEnvironment env = this;
        while (true) {
            foreach (key; env.names.keys) {
                all_names[key] = true;
            }
            if (env.parent is null)
                break;
            else
                env = env.parent;
        }
        dstring[] names = all_names.keys();
        names.sort();
        return names;
    }

    override dstring TypeName() { return "env"; }
}

class LispDictionary : LispObject {
    LispObject[LispObject] values;

    this() { }

    // default constructor with hashmap
    this(LispObject[LispObject] d) {
        foreach (key; d.keys) {
            this.values[key] = d[key];
        }
    }

    // constructor with hashmap dstring->LispObject. used to convert
    // FunctionArgs.keyword_args to a LispDictionary with *symbols* as keys
    // (NOT strings or keywords).
    this(LispObject[dstring] d) {
        foreach (key; d.keys) {
            LispSymbol sym = LispSymbol.Get(key);
            this.values[sym] = d[key];
        }
    }

    // try to convert this LispDictionary into a hashmap LispObject[dstring];
    // this will only work if the LispDictionary has only keywords as keys.
    LispObject[dstring] ToHashmap() {
        LispObject[dstring] d;
        foreach (key; values.keys) {
            if (auto kw = cast(LispSymbol) key) {
                d[kw.value] = values[key];
            } else 
                throw new TypeError(
                        format("key %s is not a symbol, got %s instead",
                            key.Repr(), key.GetType().name));
        }
        return d;
    }

    override dstring Repr() {
        dstring[] stuff = [];
        foreach (key; this.values.keys) {
            stuff ~= [key.Repr(), this.values[key].Repr()];
        }
        return "#d(" ~ join(stuff, " ") ~ ")";
    }

    override bool opEquals(Object o) {
        if (auto other = cast(LispDictionary) o) {
            return this.values == other.values;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "dict"; }

    LispObject Get(LispObject key) {
        auto p = key in this.values;
        if (p is null) {
            throw new KeyError(format("key not found: %s", key.Repr()));
        } else {
            return *p;
        }
    }

    LispObject GetDefault(LispObject key, LispObject _default) {
        try {
            return this.Get(key);
        } catch (KeyError e) {
            return _default;
        }
    }

    void Set(LispObject key, LispObject value) {
        this.values[key] = value;
    }
}

class LispModule : LispObject {
    // NOTE: this is the module's environment, so any names inside the module
    // will be defined in here. 
    LispEnvironment env;
    dstring name;
    dstring path;  // if it originated from a file

    this(dstring name, LispEnvironment env) {
        this.name = name;
        this.env = env;
    }

    override dstring Repr() {
        return format("#<module %s>"d, this.name);
    }
    override bool opEquals(Object o) {
        if (auto other = cast(LispModule) o) {
            return this.env == other.env && this.name == other.name &&
                   this.path == other.path;
        } else return super.opEquals(o);
    }
    override dstring TypeName() { return "module"; }
}

class LispVector : LispObject {
    LispObject[] values;

    this(int size, LispObject _default = null) {
        if (_default is null)
            _default = FALSE();
        this.values = [];
        this.values.length = size;
        for (auto i=0; i < size; i++) 
            this.values[i] = _default;
    }
    this(LispObject[] stuff) {
        this.values = stuff.dup;
    }

    override dstring Repr() {
        dstring[] reprs = [];
        foreach (x; this.values) {
            reprs ~= x.Repr();
        }
        return format("#(%s)"d, join(reprs, " "));
    }

    override bool opEquals(Object o) {
        if (auto other = cast(LispVector) o) {
            if (this.values.length == other.values.length) {
                for (auto i = 0; i < this.values.length; i++) {
                    if (this.values[i] != other.values[i])
                        return false;
                }
                return true;
            } else 
                return false;
        } else return super.opEquals(o);
    }

    override dstring TypeName() { return "vector"; }

    ulong GetSize() {
        return this.values.length;
    }
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

