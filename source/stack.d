// stack.d
// Simple stack class.

import errors;

const MAX_STACK_SIZE = 1000;

class Stack(T) {

    class Cell {
        T value;
        Cell next;
        this(T value, Cell next) {
            this.value = value;
            this.next = next;
        }
    }
    Cell tos = null;
    int length = 0;
    int max_size = MAX_STACK_SIZE;

    void Push(T item) {
        if (this.length >= this.max_size)
            throw new StackOverflowError("stack overflow");
        Cell cell = new Cell(item, this.tos);
        this.tos = cell;
        this.length++;
    }

    T Top() {
        if (this.tos is null) {
            throw new StackUnderflowError("stack underflow");
        } else {
            return this.tos.value;
        }
    }

    T Pop() {
        if (this.tos is null) {
            throw new StackUnderflowError("stack underflow");
        } else {
            Cell top = this.tos;
            this.tos = this.tos.next;
            this.length--;
            return top.value;
        }
    }

    void Clear() {
        while (this.tos !is null) {
            this.tos = this.tos.next;
        }
        this.length = 0;
    }

    // walk over all elements on the stack, top first. we do this by passing
    // in a function that takes an index and a value of type T.
    void Walk(void delegate(int idx, T value) f) {
        int idx = 0;
        Cell curr = this.tos;
        while (curr !is null) {
            f(idx, curr.value);
            curr = curr.next;
            idx++;
        }
    }
}

