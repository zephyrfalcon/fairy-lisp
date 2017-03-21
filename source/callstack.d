// callstack.d

import std.stdio;
import errors;
import stack;
import stackframe;
import types;

class CallStack {
    Stack!StackFrame stack;

    this() {
        this.stack = new Stack!StackFrame();
    }

    void Push(StackFrame sf) {
        this.stack.Push(sf);
    }
 
    StackFrame Pop() {
        return this.stack.Pop();
    }

    StackFrame Top() {
        return this.stack.Top();
    }

    bool IsEmpty() {
        return this.stack.length == 0;
    }

    bool IsDone() {
        return this.stack.length == 1 && this.stack.Top().is_atomic 
            && this.stack.Top().IsDone();
    }

    void Clear() {
        this.stack.Clear();
    }

    void Collapse(LispObject value) {
        StackFrame old_top = this.Pop();
        // if this was the top frame, replace it with a new frame containing
        // this value
        if (this.stack.length == 0) {
            StackFrame newsf = new StackFrame(value, old_top.env);
            // what if we get back a list as-is? then it should not be in a
            // compound expression, in this case; therefore is_atomic = true
            newsf.is_atomic = true;
            newsf.evaluated = [value];
            this.Push(newsf);
        } else {
            StackFrame top = this.Top();
            if (top.aux_data !is null) {
                throw new NotImplementedError("auxiliary data");
                // top.aux_data.Receive(value);
            } else {
                top.evaluated ~= value;
            }
        }
    }

    void Print() {
        int len = this.stack.length;
        this.stack.Walk(delegate(int idx, StackFrame sf) {
            sf.Print(len-idx-1);
        });
        writeln("::");
    }
}
