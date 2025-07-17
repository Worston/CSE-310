import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.*;

import java.io.*;

public class Main {
    public static BufferedWriter parserLogFile;
    public static BufferedWriter codeFile;
    public static BufferedWriter optimizedCodeFile;
    public static BufferedWriter errorFile;
    public static BufferedWriter lexLogFile;

    public static BufferedWriter getCodeFile() {
        return codeFile;
    }

    public static BufferedWriter getOptimizedCodeFile() {
        return optimizedCodeFile;
    }

    public static void main(String[] args) throws Exception {
        if (args.length < 1) {
            System.err.println("Usage: java Main <input_file>");
            return;
        }

        File inputFile = new File(args[0]);
        if (!inputFile.exists()) {
            System.err.println("Error opening input file: " + args[0]);
            return;
        }

        // Setup output files
        String parserLogFileName = "parserLog.txt";
        String codeFileName = "code.asm";
        String optimizedCodeFileName = "optimized_code.asm";
        String errorFileName = "error.txt";
        String lexLogFileName = "lexLog.txt";

        parserLogFile = new BufferedWriter(new FileWriter(parserLogFileName));
        codeFile = new BufferedWriter(new FileWriter(codeFileName));
        optimizedCodeFile = new BufferedWriter(new FileWriter(optimizedCodeFileName));
        errorFile = new BufferedWriter(new FileWriter(errorFileName));
        lexLogFile = new BufferedWriter(new FileWriter(lexLogFileName));

        SymbolTable symbolTable = new SymbolTable(7); 
        SymbolTable.setOutputStream(new PrintWriter(parserLogFile));

        // Create lexer and parser
        CharStream input = CharStreams.fromFileName(args[0]);
        C2105015Lexer lexer = new C2105015Lexer(input);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        C2105015Parser parser = new C2105015Parser(tokens);

        // Initialize parser's symbol table
        parser.setSymbolTable(symbolTable);

        // Begin parsing
        ParseTree tree = parser.start();
        PeepholeOptimizer.performOptimization("code.asm", "optimized_code.asm");
        System.out.println("Optimization completed. Check optimized_code.asm");
        
        // Close files
        parserLogFile.close();
        codeFile.close();
        optimizedCodeFile.close();
        errorFile.close();
        lexLogFile.close();

        System.out.println("Parsing completed. Check the output files for details.");
    }
}
