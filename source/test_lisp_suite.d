// test_lisp_suite.d

import std.array;
import std.conv;
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
        //writeln("- ", direntry.name);
        if (endsWith(direntry.name, ".test"))
            filenames ~= direntry.name;
    }
    return filenames;
}

LispTestCase[] CollectTestsInFile(string filename) {
    LispTestCase[] testcases = [];
    dstring[] current_code = [];
    File file = File(filename, "r");
    int lineno = 0;
    while (!file.eof()) {
        string sline = file.readln();
        dstring line = to!dstring(sline);
        lineno++;
        if (startsWith(line, "=>")) {
            dstring expected_result = strip(line[2..$]);
            auto testcase = LispTestCase(filename, current_code, expected_result, 
                                         lineno);
            testcases ~= testcase;
            current_code = [];
        } else {
            current_code ~= line;
        }
    }
    return testcases;
}

void RunLispTestCase(LispTestCase testcase) {
    auto intp = new Interpreter();
    auto code = join(testcase.code, "");
    //writeln("--> ", testcase.filename, " :: ", testcase.lineno); writeln(code);  // DEBUG
    auto results = intp.EvalString(code, intp.global_env);
    bool succeeds = results[$-1].Repr() == testcase.expected_result;
    if (!succeeds) {
        writeln("\n*** TEST FAILED");
        writefln("File %s, line %d", testcase.filename, testcase.lineno);
        writeln("Code:");
        writeln(join(testcase.code, ""));
        writeln("Actual result: ", results[$-1].Repr());
        writeln("Expected result: ", testcase.expected_result);
    } 
    // if we don't run AssertEquals here, we will try all Lisp tests
    // regardless whether they fail or not. using AssertEquals, we stop after
    // the first failure.
    //AssertEquals(results[$-1].Repr(), testcase.expected_result);
}

unittest {
    LispTestCase[] all_testcases = [];
    string[] testfiles = FindTestFiles();
    //writeln(testfiles);
    foreach(filename; testfiles) {
        auto testcases = CollectTestsInFile(filename);
        writefln("yay, found %d testcases in %s", testcases.length, filename);
        all_testcases ~= testcases;
    }
    writefln("Total number of tests: %d", all_testcases.length);
    foreach(i, testcase; all_testcases) {
        RunLispTestCase(testcase);
        write(i+1, " ");
        std.stdio.stdout.flush();  // does not seem to do anything :(
    }
    writeln("tested");
}

