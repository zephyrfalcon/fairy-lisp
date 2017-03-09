// test_tools.d

import tools;
import tools_test;

unittest {
    AssertEquals(EscapeString("hello"d), `"hello"`d);
    AssertEquals(EscapeString("a\nb"d), `"a\nb"`d);
}
