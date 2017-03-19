// test_lisp_suite.d

import std.file;
import std.path;
import std.stdio;
import std.string;

import interpreter;
import tools;
import tools_test;
import types;

struct LispTestCase {
    string filename;  // source
    dstring[] code;   // code to be evaluated
    dstring expected_result;  // repr of expected result
    int lineno;  // line in file that "=>" result is on
}

string[] FindTestFiles() {
    string[] filenames = [];
    string root = WhereAmI();
    string path = buildPath(root, "source", "tests");
    auto files = dirEntries(path, SpanMode.shallow);
    foreach (direntry; files) {
        // note: direntry.name is an absolute path
        writeln("- ", direntry.name);
        if (endsWith(direntry.name, ".test"))
            filenames ~= direntry.name;
    }
    return filenames;
}

unittest {
    string[] testfiles = FindTestFiles();
    writeln(testfiles);
}

