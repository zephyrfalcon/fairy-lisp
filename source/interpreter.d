// interpreter.d

import std.array;
import std.conv;
import std.format;
import std.stdio;

import errors;
import reader;
import types;

class Interpreter {
    dstring prompt = "> ";

    void MainLoop() {
        auto rd = new FileReader(stdin);
        while (true) {
            LispObject expr;
            write(this.prompt);
            try {
                expr = rd.Read();
            } catch (NoInputException e) {
                break;
            } catch (Exception e) {
                writeln("An error occurred.");  // FIXME
            }
            writeln(expr.Repr());
            // TODO: evaluate
            /*
            string line_raw = readln();
            if (line_raw is null) break;
            dstring line = to!dstring(line_raw);
            //auto writer = appender!dstring;
            //formattedWrite(writer, "%s", line);
            //write(writer.data);
            write(line);
            */
        }
    }
}

