// b_path.d
// NOTE: Eventually (almost) all this stuff can be written in pure Lisp, but
// for now, it's built-in.

import std.array;
import std.conv;
import std.file;
import std.functional : forward;
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
        string filename = baseName(spath);
        return new LispString(to!dstring(filename));
    } else
        throw new XTypeError("GET-FILE-PART", "string", fargs.args[0]);
}

// (GET-FILE-BASE-NAME filename)
// Get the "base name" of a file, i.e. the filename without any directories or
// extensions. foo/bar/baz.fs => baz
LispObject b_get_file_base_name(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto path = cast(LispString) fargs.args[0]) {
        string spath = to!string(path.value);
        string filename = baseName(spath);
        string ext = extension(filename);
        string basename = baseName(filename, ext);
        return new LispString(to!dstring(basename));
    } else
        throw new XTypeError("GET-FILE-BASE-NAME", "string", fargs.args[0]);
}

// (PATH-JOIN parts)
LispObject b_path_join(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto parts = cast(LispList) fargs.args[0]) {
        string[] sparts = [];
        LispObject[] xs = parts.ToArray();
        foreach(x; xs) {
            if (auto s = cast(LispString) x) {
                sparts ~= to!string(s.value);
            } else
                throw new XTypeError("PATH-JOIN", "string", x);
        }
        string spath = buildPath(forward!sparts);
        return new LispString(to!dstring(spath));
    } else
        throw new XTypeError("PATH-JOIN", "list", fargs.args[0]);
}
