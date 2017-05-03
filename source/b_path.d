// b_path.d

import std.conv;
import std.file;
import std.path;
import std.stdio;
import errors;
import interpreter;
import tools;
import types;

LispObject b_get_executable(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    string exepath = absolutePath(thisExePath());
    return new LispString(to!dstring(exepath));
}

LispObject b_absolute_path(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto path = cast(LispString) fargs.args[0]) {
        string spath = to!string(path.value);
        string abspath = absolutePath(spath);
        return new LispString(to!dstring(abspath));
    } else
        throw new XTypeError("ABSOLUTE-PATH", "string", fargs.args[0]);
}

// (GET-DIR-PART path)
// Get the directory part of a path.
LispObject b_get_dir_part(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto path = cast(LispString) fargs.args[0]) {
        string spath = to!string(path.value);
        string dir = dirName(spath);
        return new LispString(to!dstring(dir));
    } else
        throw new XTypeError("GET-DIR-PART", "string", fargs.args[0]);
}

// (GET-FILE-PART path)
// Get the filename part of a path.
LispObject b_get_file_part(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto path = cast(LispString) fargs.args[0]) {
        string spath = to!string(path.value);
        string filename = dirName(spath);
        return new LispString(to!dstring(filename));
    } else
        throw new XTypeError("GET-FILE-PART", "string", fargs.args[0]);
}

