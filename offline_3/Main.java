import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.*;

import java.io.*;

public class Main {
    public static BufferedWriter parserLogFile;
    public static BufferedWriter errorFile;
    public static BufferedWriter lexLogFile;

    public static int syntaxErrorCount = 0;

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

        String outputDirectory = "output/";
        String parserLogFileName = outputDirectory + "parserLog.txt";
        String errorFileName = outputDirectory + "errorLog.txt";
        String lexLogFileName = outputDirectory + "lexerLog.txt";

        new File(outputDirectory).mkdirs();

        parserLogFile = new BufferedWriter(new FileWriter(parserLogFileName));
        errorFile = new BufferedWriter(new FileWriter(errorFileName));
        lexLogFile = new BufferedWriter(new FileWriter(lexLogFileName));

        SymbolTable symbolTable = new SymbolTable(7); 
        SymbolTable.setOutputStream(new PrintWriter(parserLogFile));
        SymbolTable.setErrorStream(new PrintWriter(errorFile));

        // Create lexer and parser
        CharStream input = CharStreams.fromFileName(args[0]);
        // C8086Lexer lexer = new C8086Lexer(input);
        C2105015Lexer lexer = new C2105015Lexer(input);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        //C8086Parser parser = new C8086Parser(tokens);
        C2105015Parser parser = new C2105015Parser(tokens);

        // Remove default error listener
        parser.removeErrorListeners();

         // Initialize parser's symbol table
        parser.setSymbolTable(symbolTable);

        // Begin parsing
        ParseTree tree = parser.start();
        // parserLogFile.write("Parse tree: " + tree.toStringTree(parser) + "\n");

        // Close files
        parserLogFile.close();
        errorFile.close();
        lexLogFile.close();

        System.out.println("Parsing completed. Check the output files for details.");
    }
}
