// interpreter.d

import std.array;
import std.conv;
import std.stdio;
import std.format;

class Interpreter {
    dstring prompt = "> ";

    void MainLoop() {
        while (true) {
            write(this.prompt);
            string line_raw = readln();
            if (line_raw is null) break;
            dstring line = to!dstring(line_raw);
            //auto writer = appender!dstring;
            //formattedWrite(writer, "%s", line);
            //write(writer.data);
            write(line);
        }
    }
}

