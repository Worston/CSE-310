parser grammar C2105015Parser;

options {
    tokenVocab = C2105015Lexer;
}

@header {
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.FileWriter;
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.File;
import java.util.List;
import java.util.ArrayList;
import java.util.Stack;
}

@members {
    private SymbolTable st;
    private int labelCount = 0;
    private int stackOffset = 0;
    private boolean isFunctionStarted = false;
    private BufferedWriter tempCodeFile = null;
    private String currentVarType = null;
    private boolean isFunctionScope = false;
    private int functionStackSize = 0;
    private int parameterOffset;
    private int argumentCount = 0;
    private List<SymbolInfo> currentFunctionParameters = new ArrayList<>();
    private String currentFunctionName = "";

    public void setSymbolTable(SymbolTable st) {
        this.st = st;
    }

    // helper to write into parserLogFile
    void writeIntoParserLogFile(String message) {
        try {
            Main.parserLogFile.write(message);
            Main.parserLogFile.newLine();
            Main.parserLogFile.flush();
        } catch (IOException e) {
            System.err.println("Parser log error: " + e.getMessage());
        }
    }

    // helper to write into Main.errorFile
    void writeIntoErrorFile(String message) {
        try {
            Main.errorFile.write(message);
            Main.errorFile.newLine();
            Main.errorFile.flush();
        } catch (IOException e) {
            System.err.println("Error file write error: " + e.getMessage());
        }
    }

    private void writeCode(String code) {
        try {
            Main.codeFile.write(code);
            Main.codeFile.newLine();
            Main.codeFile.flush();
        } catch (IOException e) {
            System.err.println("Code generation error: " + e.getMessage());
        }
    }

    private void writeTempCode(String code) {
        try {
            if (tempCodeFile == null) {
                tempCodeFile = new BufferedWriter(new FileWriter("temp_code.asm"));
            }
            tempCodeFile.write(code);
            tempCodeFile.newLine();
            tempCodeFile.flush();
        } catch (IOException e) {
            System.err.println("Temp code generation error: " + e.getMessage());
        }
    }

    private void writeTempCodeBlock(String codeBlock) {
        try {
            if (tempCodeFile == null) {
                tempCodeFile = new BufferedWriter(new FileWriter("temp_code.asm"));
            }
            tempCodeFile.write(codeBlock);
            tempCodeFile.newLine();
            tempCodeFile.flush();
        } catch (IOException e) {
            System.err.println("Temp code generation error: " + e.getMessage());
        }
    }

    private void appendTempFileToMain() {
        try {
            if (tempCodeFile != null) {
                tempCodeFile.close();
            }
            
            // Read temp file and append to main file
            File tempFile = new File("temp_code.asm");
            if (tempFile.exists()) {
                BufferedReader reader = new BufferedReader(new FileReader(tempFile));
                String line;
                while ((line = reader.readLine()) != null) {
                    writeCode(line);
                }
                reader.close();
                //tempFile.delete(); 
            }
        } catch (IOException e) {
            System.err.println("Error appending temp file: " + e.getMessage());
        }
    }

    private void writeMainHeader() {
        writeTempCode("main PROC");
        writeTempCode("\tMOV AX, @DATA");
        writeTempCode("\tMOV DS, AX");
        writeTempCode("\tPUSH BP");
        writeTempCode("\tMOV BP, SP");
    }

    private void writeMainEnder() { 
        writeTempCode("\tADD SP, " + functionStackSize);
        writeTempCode("\tPOP BP");
        writeTempCode("\tMOV AX, 4CH");
        writeTempCode("\tINT 21H");
        writeTempCode("main ENDP");
        writeTempCode("END main");
    }

    private String newLabel() {
        return "L" + (++labelCount);
    }

    private boolean isGlobalScope() {
        return st.getCurrentScope().getId().equals("1");
    }

    private void resetStackOffset() {
        functionStackSize = 0;
        stackOffset = 0;
    }

    private int getNextStackOffset() {
        stackOffset += 2;
        functionStackSize += 2;
        return stackOffset;
    }

    private void startCodeSegmentIfNeeded() {
        if (!isFunctionStarted) {
            writeCode(".CODE");
            isFunctionStarted = true;
        }
    }

    private void adjustParameterOffsets() {
        int paramCount = currentFunctionParameters.size();
        for (int i = 0; i < paramCount; i++) {
            SymbolInfo param = currentFunctionParameters.get(i);
            int newOffset = 4 + (2 * (paramCount - 1 - i));
            param.setOffset(newOffset);
        }
        
        // Clear the list for next function
        currentFunctionParameters.clear();
    }
}


start 
    : 
    {   
        writeCode(".MODEL SMALL");
        writeCode(".STACK 100H");
        writeCode(".DATA");
        writeCode("\tnumber DB \"00000$\"");
    } program {
        appendTempFileToMain();
        writeIntoParserLogFile("start : program");
    }
    ;

program 
    : program unit
      {
        writeIntoParserLogFile("program : program unit");
      } 
    | unit
      {
        writeIntoParserLogFile("program : unit");
      }
    ;

unit 
    : var_declaration
      {
        writeIntoParserLogFile("unit : var_declaration");
      }
    | func_declaration
      {
        writeIntoParserLogFile("unit : func_declaration");
      }
    | func_definition
      {
        writeIntoParserLogFile("unit : func_definition");
      }
    ;

func_declaration 
    : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
      {
        writeIntoParserLogFile("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
        String funcName = $ID.text;
        String returnType = $type_specifier.text;
        SymbolInfo funcSymbol = new SymbolInfo(funcName, "ID");
        funcSymbol.setDataType(returnType);
        funcSymbol.setFunction(true);
        st.insert(funcSymbol);
      }
    | type_specifier ID LPAREN RPAREN SEMICOLON
      {
        writeIntoParserLogFile("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON");
        String funcName = $ID.text;
        String returnType = $type_specifier.text;
        SymbolInfo funcSymbol = new SymbolInfo(funcName, "ID");
        funcSymbol.setDataType(returnType);
        funcSymbol.setFunction(true);
        st.insert(funcSymbol);
      }  
    ;

func_definition 
    : t=type_specifier ID LPAREN
      {
        parameterOffset = 4;
        currentFunctionParameters.clear();  // ← Added this line

        String funcName = $ID.text;
        //currentFunctionName = funcName;    //added to test return
        String returnType = $t.text;
        SymbolInfo funcSymbol = new SymbolInfo(funcName, "ID");
        funcSymbol.setDataType(returnType);
        funcSymbol.setFunction(true);
        st.insert(funcSymbol);

        //added for scoping
        st.enterScope();

        startCodeSegmentIfNeeded();
        isFunctionScope = true;
        
        if (funcName.equals("main")) {
            writeMainHeader();
        } else{
            String codeBlock = funcName + " PROC\n" + "\tPUSH BP\n" + "\tMOV BP, SP";
            writeTempCodeBlock(codeBlock);
        }
      } 
      parameter_list RPAREN
      { 
        // startCodeSegmentIfNeeded();
        // isFunctionScope = true;
        
        // if (funcName.equals("main")) {
        //     writeMainHeader();
        // } else{
        //     String codeBlock = funcName + " PROC\n" + "\tPUSH BP\n" + "\tMOV BP, SP";
        //     writeTempCodeBlock(codeBlock);
        // }
        adjustParameterOffsets();  // ← Added this line
      } 
      compound_statement
      {
        writeIntoParserLogFile("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement");

        if (funcName.equals("main")) {
            writeMainEnder();
        } else {
            String codeBlock = "\tADD SP, " + functionStackSize + "\n" + "\tPOP BP\n" +"\tRET\n" +funcName + " ENDP";
            writeTempCodeBlock(codeBlock);
        }

        //added for scoping
        st.exitScope();
      }
    | t=type_specifier ID LPAREN RPAREN 
      {
        currentFunctionParameters.clear();  // ← Added this line

        String funcName = $ID.text;
        String returnType = $t.text;

        SymbolInfo funcSymbol = new SymbolInfo(funcName, "ID");
        funcSymbol.setDataType(returnType);
        funcSymbol.setFunction(true);
        st.insert(funcSymbol);

        //added for scoping
        st.enterScope();

        startCodeSegmentIfNeeded();
        isFunctionScope = true;

        if (funcName.equals("main")) {
            writeMainHeader();
        } else{
            String codeBlock = funcName + " PROC\n" + "\tPUSH BP\n" + "\tMOV BP, SP";
            writeTempCodeBlock(codeBlock);
        }
      } 
      compound_statement
      {
        writeIntoParserLogFile("func_definition : type_specifier ID LPAREN RPAREN compound_statement");
        if (funcName.equals("main")) {
            writeMainEnder();
        } else {
            String codeBlock = "\tADD SP, " + functionStackSize + "\n" + "\tPOP BP\n" +"\tRET\n" + funcName + " ENDP";
            writeTempCodeBlock(codeBlock);
        }
        //added for scoping
        st.exitScope();
      }   
    ;

parameter_list 
    : parameter_list COMMA type_specifier ID
      {
        writeIntoParserLogFile("parameter_list : parameter_list COMMA type_specifier ID");
        SymbolInfo param = new SymbolInfo($ID.text, "ID");
        param.setDataType($type_specifier.text);
        param.setOffset(parameterOffset);
        param.setIsParameter(true);
        parameterOffset += 2;
        currentFunctionParameters.add(param); //sdded
        st.insert(param);
      }
    | parameter_list COMMA type_specifier
      {
        writeIntoParserLogFile("parameter_list : parameter_list COMMA type_specifier");
      }
    | type_specifier ID
      {
        writeIntoParserLogFile("parameter_list : type_specifier ID");
        SymbolInfo param = new SymbolInfo($ID.text, "ID");
        param.setDataType($type_specifier.text);
        param.setOffset(parameterOffset);
        param.setIsParameter(true);
        parameterOffset += 2; 
        currentFunctionParameters.add(param); //added
        st.insert(param);
      }
    | type_specifier
      {
        writeIntoParserLogFile("parameter_list : type_specifier");
      }
    ;

compound_statement 
    : LCURL {
        //st.enterScope();
        if (!isFunctionScope) {
            st.enterScope();
        }
        if (isFunctionScope) {
            resetStackOffset();
            isFunctionScope = false;
        }
      } statements RCURL {
        writeIntoParserLogFile("compound_statement : LCURL statements RCURL");
        //st.exitScope();
        if (!isFunctionScope) {
            st.exitScope();
        }
      }
    | LCURL {
        //st.enterScope();
        if (!isFunctionScope) {
            st.enterScope();
        }
        if (isFunctionScope) {
            resetStackOffset();
            isFunctionScope = false;
        }
      } RCURL {
        writeIntoParserLogFile("compound_statement : LCURL RCURL");
        //st.exitScope();
        if (!isFunctionScope) {
            st.exitScope();
        }
      }
    ;

var_declaration 
    : type_specifier 
      {
        currentVarType = $type_specifier.text;
      } declaration_list SEMICOLON
      {
        writeIntoParserLogFile("var_declaration : type_specifier declaration_list SEMICOLON");
        currentVarType = null;
      }
    ;

type_specifier 
    : INT
      {
        writeIntoParserLogFile("type_specifier : INT");
      }
    | FLOAT
      {
        writeIntoParserLogFile("type_specifier : FLOAT");
      }
    | VOID
      {
        writeIntoParserLogFile("type_specifier : VOID");
      }
    ;

declaration_list 
    : declaration_list COMMA ID
      {
        writeIntoParserLogFile("declaration_list : declaration_list COMMA ID");
        SymbolInfo symbol = new SymbolInfo($ID.text, "ID");
        symbol.setDataType(currentVarType);
    
        if (isGlobalScope()) {
            writeCode("\t"+$ID.text + " DW 1 DUP (0000H)");
        } else {
            int offset = getNextStackOffset();
            symbol.setOffset(offset);
            writeTempCode("\tSUB SP, 2");
        }
        String str = isGlobalScope()? "Global Scope" : "Local Scope";
        System.out.println(str);
        st.insert(symbol);
        System.out.println(symbol);
      }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
      {
        writeIntoParserLogFile("declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD");
        SymbolInfo symbol = new SymbolInfo($ID.text, "ID");
        symbol.setDataType(currentVarType);
        symbol.setArray(true);
        int arraySize = Integer.parseInt($CONST_INT.text);
        symbol.setArraySize(arraySize);
        
        if (isGlobalScope()) {
            writeCode($ID.text + " DW " + arraySize + " DUP (0000H)");
        } else {
            int offset = getNextStackOffset();
            symbol.setOffset(offset);
            String codeBlock = "SUB SP, " + (arraySize * 2);
            writeTempCodeBlock(codeBlock);
            functionStackSize += (arraySize - 1) * 2;
            stackOffset += (arraySize - 1) * 2; 
        }
        String str = isGlobalScope()? "Global Scope" : "Local Scope";
        System.out.println(str);
        st.insert(symbol);
      } 
    | ID
      {
        writeIntoParserLogFile("declaration_list : ID");
        SymbolInfo symbol = new SymbolInfo($ID.text, "ID");
        symbol.setDataType(currentVarType);
        
        if (isGlobalScope()) {
            writeCode("\t"+$ID.text + " DW 1 DUP (0000H)");
        } else {
            int offset = getNextStackOffset();
            symbol.setOffset(offset);
            writeTempCode("\tSUB SP, 2");
        }
        String str = isGlobalScope()? "Global Scope" : "Local Scope";
        System.out.println(str);
        st.insert(symbol);
        System.out.println(symbol);
      } 
    | ID LTHIRD CONST_INT RTHIRD
      {
        writeIntoParserLogFile("declaration_list : ID LTHIRD CONST_INT RTHIRD");
        SymbolInfo symbol = new SymbolInfo($ID.text, "ID");
        symbol.setDataType(currentVarType);
        symbol.setArray(true);
        int arraySize = Integer.parseInt($CONST_INT.text);
        symbol.setArraySize(arraySize);
        
        if (isGlobalScope()) {
            writeCode($ID.text + " DW 1 DUP (0000H)");
        } else {
            int offset = getNextStackOffset();
            symbol.setOffset(offset);
            String codeBlock = "SUB SP, " + (arraySize * 2);
            writeTempCodeBlock(codeBlock);
            functionStackSize += (arraySize - 1) * 2;
            stackOffset += (arraySize - 1) * 2; 
        }
        st.insert(symbol);
      } 
    ;

statements 
    : statement
      {
        writeIntoParserLogFile("statements : statement");
      }
    | statements statement
      {
        writeIntoParserLogFile("statements : statements statement");
      }
    ;

statement 
    : var_declaration
      {
        writeIntoParserLogFile("statement : var_declaration");
      }
    | expression_statement
      {
        writeIntoParserLogFile("statement : expression_statement");
      }
    | compound_statement
      {
        writeIntoParserLogFile("statement : compound_statement");
      }
    | FOR LPAREN expression_statement 
      {
        String conditionLabel = newLabel();
        String incrementLabel = newLabel();
        String bodyLabel = newLabel();
        String endLabel = newLabel();

        writeTempCode(conditionLabel + ":");
      } 
      expression_statement 
      {
        writeTempCode("\tCMP AX, 0");
        writeTempCode("\tJE " + endLabel);
        writeTempCode("\tJMP " + bodyLabel);
        writeTempCode(incrementLabel + ":");
      } 
      expression RPAREN 
      {
        writeTempCode("\tJMP " + conditionLabel);
        writeTempCode(bodyLabel + ":");
      } 
      statement
      {
        writeIntoParserLogFile("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");
        writeTempCode("\tJMP " + incrementLabel);
        writeTempCode(endLabel + ":");
      }
    | IF LPAREN 
      { 
        String conditionLabel = newLabel();
        writeTempCode(conditionLabel + ":");
      } expression RPAREN
      {
        String nextLabel = newLabel();
        writeTempCode("\tCMP AX, 0");
        writeTempCode("\tJE " + nextLabel);
      }
      statement
      {
        writeIntoParserLogFile("statement : IF LPAREN expression RPAREN statement");
        // String codeBlock = "\tJMP " + nextLabel + "\n" +
        //                     elseLabel + ":\n" +
        //                     nextLabel + ":\n";
        // writeTempCodeBlock(codeBlock);    
        writeTempCode(nextLabel + ":");                
      }
    | IF LPAREN
      {
        String conditionLabel = newLabel();
        writeTempCode(conditionLabel + ":");
      } expression RPAREN 
      {
        String elseLabel = newLabel();
        String nextLabel = newLabel();
        writeTempCode("\tCMP AX, 0");
        writeTempCode("\tJE " + elseLabel);
      } 
      statement ELSE 
      {
        writeTempCode("\tJMP " + nextLabel);
        writeTempCode(elseLabel + ":");
      } statement
      {
        writeIntoParserLogFile("statement : IF LPAREN expression RPAREN statement ELSE statement");
        writeTempCode(nextLabel + ":");
      }
    | WHILE LPAREN 
      {
        String conditionLabel = newLabel();
        String endLabel = newLabel();
        writeTempCode(conditionLabel + ":");
      } expression RPAREN
      {
        writeTempCode("\tCMP AX, 0");
        writeTempCode("\tJE " + endLabel);
      }
      statement
      {
        writeIntoParserLogFile("statement : WHILE LPAREN expression RPAREN statement");
        writeTempCode("\tJMP " + conditionLabel);
        writeTempCode(endLabel + ":");
      }
    | PRINTLN LPAREN ID RPAREN SEMICOLON
      {
        writeIntoParserLogFile("statement : PRINTLN LPAREN ID RPAREN SEMICOLON");
        String varName = $ID.text;
        SymbolInfo symbol = st.lookup(varName);
        int lineNumber = $PRINTLN.getLine();
        String label = newLabel();
        writeTempCode(label + ":");
        
        if (symbol != null) {
            if (isGlobalScope() || symbol.getOffset() == 0) {
                // Global variable
                writeTempCode("\tMOV AX, " + varName + "       ; Line " + lineNumber);
            } else {
                // Local variable
                writeTempCode("\tMOV AX, [BP-" + symbol.getOffset() + "]       ; Line " + lineNumber);
            }
            writeTempCode("\tCALL print_output");
            writeTempCode("\tCALL new_line");
        }
      }
    | RETURN expression SEMICOLON
      {
        writeIntoParserLogFile("statement : RETURN expression SEMICOLON");
        String label = newLabel();
        writeTempCode(label + ":");

        //return e maybe jhamela. ektu change korte hobe. Checking 25 mile kina
      }
    ;

expression_statement   
    : SEMICOLON
      {
        writeIntoParserLogFile("expression_statement : SEMICOLON");
      }
    | expression SEMICOLON
      {
        writeIntoParserLogFile("expression_statement : expression SEMICOLON");
      }
    ;

variable 
    : ID
      {
        writeIntoParserLogFile("variable : ID");
      }
    | ID LTHIRD expression RTHIRD
      {
        writeIntoParserLogFile("variable : ID LTHIRD expression RTHIRD");
        String varName = $ID.text;
        SymbolInfo symbol = st.lookup(varName);
        if (symbol != null) {
            writeTempCode("\tMOV BX, AX");
            writeTempCode("\tSHL BX, 1");  // Multiply by 2 for word addressing
            if (isGlobalScope() || symbol.getOffset() == 0) {
                writeTempCode("\tMOV AX, " + varName + "[BX]");
            } else {
                writeTempCode("\tMOV AX, [BP-" + symbol.getOffset() + "+BX]");
            }
        }
      }
    ;

expression  
    : logic_expression
      {
        writeIntoParserLogFile("expression : logic_expression");
      }
    | variable ASSIGNOP 
      {
        String label = newLabel();
        writeTempCode(label + ":");
      } 
      logic_expression
      {
        writeIntoParserLogFile("expression : variable ASSIGNOP logic_expression");
        // logic_expression result is in AX
        String varName = $variable.text;
        SymbolInfo symbol = st.lookup(varName);
        int lineNumber = $ASSIGNOP.getLine();
        
        if (symbol != null) {
            if (isGlobalScope() || symbol.getOffset() == 0) {
                writeTempCode("\tMOV " + varName + ", AX       ; Line " + lineNumber);
            } else {
                //writeTempCode("\tMOV [BP-" + symbol.getOffset() + "], AX       ; Line " + lineNumber);
                if (symbol.isParameter()) {
                    writeTempCode("\tMOV [BP+" + symbol.getOffset() + "], AX");
                } else {
                    writeTempCode("\tMOV [BP-" + symbol.getOffset() + "], AX");
                }
            }
            writeTempCode("\tPUSH AX");
            writeTempCode("\tPOP AX");
        }
      }
    ;

logic_expression 
    : rel_expression
      {
        writeIntoParserLogFile("logic_expression : rel_expression");
      }
    | rel_expression LOGICOP
      {
        writeTempCode("\tPUSH AX");
      }
      rel_expression
      {
        writeIntoParserLogFile("logic_expression : rel_expression LOGICOP rel_expression");
        String op = $LOGICOP.text;
        int lineNumber = $LOGICOP.getLine();

        if (op.equals("||")) {
            String trueLabel = newLabel();
            String falseLabel = newLabel();
            String endLabel = newLabel();
            
            String codeBlock = "\tMOV DX, AX\n" +
                               "\tPOP AX\n" +
                               "\tCMP AX, 0\n" +
                               "\tJNE " + trueLabel + "\n" +
                               "\tCMP DX, 0\n" +
                               "\tJNE " + trueLabel +"\n" +
                               "\tMOV AX, 0\n"+
                               "\tJMP " + endLabel +"\n"+
                               trueLabel + ":\n"+
                               "\tMOV AX, 1       ; Line " + lineNumber + "\n"+
                               endLabel + ":";
            writeTempCodeBlock(codeBlock);                   
        } else if (op.equals("&&")) {
            String trueLabel = newLabel();
            String falseLabel = newLabel();
            String endLabel = newLabel();
            
            String codeBlock = "\tMOV DX, AX\n" +
                               "\tPOP AX\n" +
                               "\tCMP AX, 0\n"+
                               "\tJE " + falseLabel +"\n" + 
                               "\tCMP DX, 0\n" +
                               "\tJE " + falseLabel + "\n" +
                               "\tMOV AX, 1       ; Line " + lineNumber + "\n"+
                               "\tJMP " + endLabel +"\n"+
                               falseLabel+":\n" + 
                               "\tMOV AX, 0\n" +
                               endLabel + ":";
            writeTempCodeBlock(codeBlock);      
        }
      }
    ;

rel_expression 
    : simple_expression
      {
        writeIntoParserLogFile("rel_expression : simple_expression");
      }
    | simple_expression RELOP
      {
        writeTempCode("\tPUSH AX");
      }
      simple_expression
      {
        writeIntoParserLogFile("rel_expression : simple_expression RELOP simple_expression");
        String op = $RELOP.text;
        int lineNumber = $RELOP.getLine();
        
        String trueLabel = newLabel();
        String falseLabel = newLabel();
        String endLabel = newLabel();

        String codeBlock = "\tMOV DX, AX\n" +
                           "\tPOP AX\n" +
                           "\tCMP AX, DX\n";

        if (op.equals("<=")) {
            codeBlock += "\tJLE " + trueLabel + "\n";
        } else if (op.equals("<")) {
            codeBlock += "\tJL " + trueLabel + "\n";
        } else if (op.equals(">=")) {
            codeBlock += "\tJGE " + trueLabel + "\n";
        } else if (op.equals(">")) {
            codeBlock += "\tJG " + trueLabel + "\n";
        } else if (op.equals("==")) {
            codeBlock += "\tJE " + trueLabel + "\n";
        } else if (op.equals("!=")) {
            codeBlock += "\tJNE " + trueLabel + "\n";
        }   

        codeBlock += "\tJMP " + falseLabel + "\n" +
                      trueLabel + ":\n" +
                      "\tMOV AX, 1       ; Line " + lineNumber +"\n"+
                      "\tJMP " + endLabel + "\n" +
                      falseLabel + ":\n" +
                      "\tMOV AX, 0\n" +
                      endLabel + ":";
        writeTempCodeBlock(codeBlock);                 
      }
    ;

simple_expression 
    : term
      {
        writeIntoParserLogFile("simple_expression : term");
      }
    | simple_expression ADDOP
      {
        writeTempCode("\tPUSH AX");
      } 
      term
      {
        writeIntoParserLogFile("simple_expression : simple_expression ADDOP term");
        String op = $ADDOP.text;
        int lineNumber = $ADDOP.getLine();
        
        //System.out.println("ADDOP: " + op + " at line " + lineNumber);
        writeTempCode("\tMOV DX, AX");
        writeTempCode("\tPOP AX");
        
        if (op.equals("+")) {
            writeTempCode("\tADD AX, DX       ; Line " + lineNumber);
        } else if (op.equals("-")) {
            writeTempCode("\tSUB AX, DX");
        }
      }
    ;

term 
    : unary_expression
      {
        writeIntoParserLogFile("term : unary_expression");
      }
    | term MULOP
      {
         writeTempCode("\tPUSH AX");
      } 
      unary_expression
      {
        writeIntoParserLogFile("term : term MULOP unary_expression");
        String op = $MULOP.text;
        int lineNumber = $MULOP.getLine();

        //System.out.println("MULOP: " + op + " at line " + lineNumber);

        String codeBlock = "\tMOV CX, AX\n"+
                           "\tPOP AX\n";
        if (op.equals("*")) {
            codeBlock += "\tCWD\n" +
                          "\tMUL CX       ; Line " + lineNumber;
        } else if (op.equals("/")) {
            codeBlock += "\tCWD\n" +
                          "\tDIV CX\n";
        } else if (op.equals("%")) {
            codeBlock += "\tCWD\n" +
                         "\tDIV CX\n" +
                         "\tMOV AX, DX"; 
        }                   
        writeTempCodeBlock(codeBlock);
      }
    ;

unary_expression 
    : ADDOP unary_expression
      {
        writeIntoParserLogFile("unary_expression : ADDOP unary_expression");
        String op = $ADDOP.text;
        int lineNumber = $ADDOP.getLine();
        
        if (op.equals("-")) {
            writeTempCode("\tNEG AX       ; Line " + lineNumber);
        }
      }
    | NOT unary_expression
      {
        writeIntoParserLogFile("unary_expression : NOT unary_expression");
        String falseLabel = newLabel();
        String endLabel = newLabel();
        String codeBlock = "\tCMP AX, 0\n"+
                           "\tJE " + falseLabel + "\n"+
                           "\tMOV AX, 0\n"+  
                           "\tJMP " + endLabel +"\n"+
                           falseLabel +":\n"+
                           "\tMOV AX, 1\n" +
                           endLabel+ ":";
        writeTempCodeBlock(codeBlock);
      }
    | factor
      {
        writeIntoParserLogFile("unary_expression : factor");
      }
    ;

factor 
    : variable
      {
        writeIntoParserLogFile("factor : variable");
        String varName = $variable.text;
        SymbolInfo symbol = st.lookup(varName);
        
        if (symbol != null) {
            if (isGlobalScope() || symbol.getOffset() == 0) {
                //GLOBAL Variable
                writeTempCode("\tMOV AX, " + varName);
            } else {
                //writeTempCode("\tMOV AX, [BP-" + symbol.getOffset() + "]");
                //LOCAL variable or parameter
                if (symbol.isParameter()) { 
                    writeTempCode("\tMOV AX, [BP+" + symbol.getOffset() + "]");
                } else { 
                    writeTempCode("\tMOV AX, [BP-" + symbol.getOffset() + "]");
                }
            }
        }
      }
    | ID LPAREN{

      } argument_list RPAREN
      {
        writeIntoParserLogFile("factor : ID LPAREN argument_list RPAREN");
        String funcName = $ID.text;
        writeTempCode("\tCALL " + funcName);
        
        if (argumentCount > 0) {
            writeTempCode("\tADD SP, " + (argumentCount * 2));
        }
      }
    | LPAREN expression RPAREN
      {
        writeIntoParserLogFile("factor : LPAREN expression RPAREN");
      }
    | CONST_INT
      {
        writeIntoParserLogFile("factor : CONST_INT");
        int lineNumber = $CONST_INT.getLine();
        writeTempCode("\tMOV AX, " + $CONST_INT.text + "       ; Line " + lineNumber);
      }
    | CONST_FLOAT
      {
        writeIntoParserLogFile("factor : CONST_FLOAT");
      }
    | variable INCOP
      {
        writeIntoParserLogFile("factor : variable INCOP");
        int lineNumber = $INCOP.getLine();

        String varName = $variable.text;
        SymbolInfo symbol = st.lookup(varName);
        if (symbol != null) {
            if (isGlobalScope() || symbol.getOffset() == 0) {
                writeTempCode("\tMOV " + varName + ", AX");
            } else {
                writeTempCode("\tMOV [BP-" + symbol.getOffset() + "], AX");
            }
        }

        writeTempCode("\tPUSH AX");  
        writeTempCode("\tINC AX");

        if (symbol != null) {
            if (isGlobalScope() || symbol.getOffset() == 0) {
                writeTempCode("\tMOV " + varName + ", AX");
            } else {
                writeTempCode("\tMOV [BP-" + symbol.getOffset() + "], AX");
            }
        }
        
        writeTempCode("\tPOP AX");   // Restore original value for expression
      }
    | variable DECOP
      {
        writeIntoParserLogFile("factor : variable DECOP");
        int lineNumber = $DECOP.getLine();
        String varName = $variable.text;
        SymbolInfo symbol = st.lookup(varName);

        if (symbol != null) {
            if (isGlobalScope() || symbol.getOffset() == 0) {
                //writeTempCode("\tMOV " + varName + ", AX");
                writeTempCode("\tMOV AX, " + varName + "       ; Line " + lineNumber);
            } else {
                //writeTempCode("\tMOV [BP-" + symbol.getOffset() + "], AX");
                writeTempCode("\tMOV AX, [BP-" + symbol.getOffset() + "]       ; Line " + lineNumber);
            }
        }
        
        writeTempCode("\tPUSH AX");  // Save current value
        writeTempCode("\tDEC AX");   // Decrement
        
        if (symbol != null) {
            if (isGlobalScope() || symbol.getOffset() == 0) {
                writeTempCode("\tMOV " + varName + ", AX");
            } else {
                writeTempCode("\tMOV [BP-" + symbol.getOffset() + "], AX");
            }
        }
        writeTempCode("\tPOP AX");   // Restore original value for expression
      }
    ;

argument_list 
    : arguments
      {
        writeIntoParserLogFile("argument_list : arguments");
      }
    |
      {
        writeIntoParserLogFile("argument_list : ");
      }
    ;

arguments 
    : arguments COMMA logic_expression
      {
        writeIntoParserLogFile("arguments : arguments COMMA logic_expression");
        writeTempCode("\tPUSH AX");
        argumentCount++;
      }
    | logic_expression
      {
        writeIntoParserLogFile("arguments : logic_expression");
        writeTempCode("\tPUSH AX");
        argumentCount = 1;
      }
    ;