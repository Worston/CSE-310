parser grammar C8086Parser;

options {
    tokenVocab = C8086Lexer;
}

@header {
import java.io.BufferedWriter;
import java.io.IOException;
import java.util.List;
import java.util.ArrayList;
}

@members {
    private SymbolTable symbolTable;
    private String currentVarType;

    public void setSymbolTable(SymbolTable st) {
        this.symbolTable = st;
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

    String determineArithmeticType(String type1, String type2) {
        if (type1.equals("error") || type2.equals("error")) {
            return "error";
        }
        if (type1.equals("void") || type2.equals("void")) {
            return "error"; 
        }
        if (type1.equals("float") || type2.equals("float")) {
            return "float"; 
        }
        if (type1.equals("int") && type2.equals("int")) {
            return "int";
        }
        return "unknown";
    }
    
    // Get function return type
    String getFunctionReturnType(String functionName, int lineNumber) {
        if (symbolTable == null) return "unknown";
        
        SymbolInfo func = symbolTable.lookup(functionName);
        if (func == null) {
            return "error";
        } else if (!func.isFunction()) {
            return "error";
        }
        
        return func.getDataType();
    }
    
    // Check if a variable is declared
    boolean isVariableDeclared(String varName) {
        if (symbolTable == null) return false;
        return symbolTable.isDeclared(varName);
    }
    
    // Get variable type safely
    String getVariableType(String varName) {
        if (symbolTable == null) return "unknown";
        
        SymbolInfo symbol = symbolTable.lookup(varName);
        if (symbol != null) {
            return symbol.getDataType();
        }
        return "error"; // Variable not found
    }

    void checkAssignmentCompatibility(String leftType, String rightType, int lineNumber) {
        if (leftType.equals("error") || rightType.equals("error") || 
            leftType.equals("unknown") || rightType.equals("unknown")) {
            return;
        }
        
        if (leftType.equals("void") || rightType.equals("void")) {
            String errorMsg = "Error at line " + lineNumber + ": Void function used in expression\n";
            writeIntoParserLogFile(errorMsg);
            writeIntoErrorFile(errorMsg);
            Main.syntaxErrorCount++;
            return;
        }

        if (!isAssignmentCompatible(leftType, rightType)) {
            String errorMsg = "Error at line " + lineNumber + ": Type Mismatch\n";
            writeIntoParserLogFile(errorMsg);
            writeIntoErrorFile(errorMsg);
            Main.syntaxErrorCount++;
        }
    }

    void checkVoidInExpression(String type1, String type2, int lineNumber) {
        if (type1.equals("void") || type2.equals("void")) {
            String errorMsg = "Error at line " + lineNumber + ": Void function used in expression\n";
            writeIntoParserLogFile(errorMsg);
            writeIntoErrorFile(errorMsg);
            Main.syntaxErrorCount++;
            return;
        }
    }

    void checkFunctionCall(String funcName, List<String> argTypes, int lineNumber){
        if(symbolTable == null) return;

        SymbolInfo func = symbolTable.lookup(funcName);
        if (func == null) {
            String errorMsg = "Error at line " + lineNumber + ": Undefined function " + funcName + "\n";
            writeIntoParserLogFile(errorMsg);
            writeIntoErrorFile(errorMsg);
            Main.syntaxErrorCount++;
            return;
        }

        if (!func.isFunction()) {
            String errorMsg = "Error at line " + lineNumber + ": " + funcName + "' is not a function\n";
            writeIntoParserLogFile(errorMsg);
            writeIntoErrorFile(errorMsg);
            Main.syntaxErrorCount++;
            return;
        }

        List<SymbolInfo> parameters = func.getParameters();
        int expectedCount = (parameters != null) ? parameters.size() : 0;
        int actualCount = argTypes.size();
        
        if (expectedCount != actualCount) {
            String errorMsg = "Error at line " + lineNumber + ": Total number of arguments mismatch with declaration in function " + funcName + "\n";
            writeIntoParserLogFile(errorMsg);
            writeIntoErrorFile(errorMsg);
            Main.syntaxErrorCount++;
            return;
        }

        if (parameters != null) {
            for (int i = 0; i < parameters.size(); i++) {
                String expectedType = parameters.get(i).getDataType();
                String actualType = argTypes.get(i);
        
                if (expectedType.equals("error") || actualType.equals("error") ||
                    expectedType.equals("unknown") || actualType.equals("unknown")) {
                    continue;
                }
                
                if (!isArgumentCompatible(expectedType, actualType)) {
                    String errorMsg = "Error at line " + lineNumber + ": " + (i + 1) + "th argument mismatch in function " + funcName + "\n";
                    writeIntoParserLogFile(errorMsg);
                    writeIntoErrorFile(errorMsg);
                    Main.syntaxErrorCount++;
                    return; 
                }
            }
        }
    } 

    boolean isArgumentCompatible(String parameterType, String argumentType) {
        if (parameterType.equals(argumentType)) {
            return true;
        }
        if (parameterType.equals("float") && argumentType.equals("int")) {
            return true;
        }
        return false;
    }
    
    boolean isAssignmentCompatible(String leftType, String rightType) {
        if (leftType.equals(rightType)) {
            return true;
        }
        if (leftType.equals("float") && rightType.equals("int")) {
            return true; 
        }
        return false;
    }
}

start
    : program
      {
        writeIntoParserLogFile(
          "Line " + $program.stop.getLine() + ": start : program\n"
        );

        if (this.symbolTable != null) {
          symbolTable.printAllScopes();
        }

        writeIntoParserLogFile(
            "Total number of lines: " + $program.stop.getLine() + "\n"
            + "Total number of errors: " + Main.syntaxErrorCount 
        );
      }
    ;

program
    returns [String unit_list]
    : pg=program unit
      {
        $unit_list = $pg.unit_list + "\n" + $unit.unit_name;
        writeIntoParserLogFile(
            "Line " + $unit.stop.getLine() + ": program : program unit\n"
        ); 
        writeIntoParserLogFile(
            $unit_list + "\n"
        ); 
      }  
    | unit
      {
        $unit_list = $unit.unit_name;
        writeIntoParserLogFile(
            "Line " + $unit.stop.getLine() + ": program : unit\n"
        ); 
        writeIntoParserLogFile(
            $unit.unit_name + "\n"
        ); 
      }  
    ;

unit
    returns [String unit_name] 
    : vd=var_declaration
      {
        $unit_name = $vd.vardec_list;
        writeIntoParserLogFile(
            "Line " + $vd.stop.getLine() + ": unit : var_declaration\n"
        );  
        writeIntoParserLogFile(
            $vd.vardec_list + "\n"
        );  
      }
    | fd=func_declaration
      {
        $unit_name = $fd.func_dec_name;
        writeIntoParserLogFile(
            "Line " + $fd.stop.getLine() + ": unit : func_declaration\n"
        ); 
        writeIntoParserLogFile(
            $fd.func_dec_name + "\n"
        ); 
      }  
    | fdf=func_definition
      {
        $unit_name = $fdf.func_def_name;
        writeIntoParserLogFile(
            "Line " + $fdf.stop.getLine() + ": unit : func_definition\n"
        ); 
        writeIntoParserLogFile(
            $unit_name + "\n"
        ); 
      }  
    ;

func_declaration
    returns [String func_dec_name]
    : t=type_specifier ID LPAREN 
      {
          if (symbolTable != null) {
            symbolTable.clearPendingParameters();
          }
      }
      pl=parameter_list RPAREN sm=SEMICOLON
      {
          $func_dec_name=$t.name_line +" "+ $ID.text + "(" + $pl.name_list + ");";
          writeIntoParserLogFile(
              "Line " + $sm.getLine() + ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n"
          );
          writeIntoParserLogFile($func_dec_name + "\n");

          if (symbolTable != null) {
              List<SymbolInfo> params = symbolTable.getPendingParameters();
              symbolTable.insertFunction($ID.text, $t.name_line, params);
              symbolTable.clearPendingParameters();
          }
      }
    | t=type_specifier ID LPAREN RPAREN sm=SEMICOLON
      {
        $func_dec_name=$t.name_line +" "+ $ID.text + "();";
        writeIntoParserLogFile(
            "Line " + $sm.getLine() + ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n"
        );
        writeIntoParserLogFile(
            $func_dec_name + "\n"
        );

        if (symbolTable != null) {
            symbolTable.insertFunction($ID.text,$t.name_line,null);
        }
      }
    ;

func_definition
    returns [String func_def_name]
    : t=type_specifier ID LPAREN
      {
        if (symbolTable != null) {
          symbolTable.clearPendingParameters();
        }
      }
      pl=parameter_list RPAREN 
      { 
        // will need signature and other checking
        if (symbolTable != null) {
          List<SymbolInfo> params = symbolTable.getPendingParameters();
          symbolTable.insertFunction($ID.text, $t.name_line, params, $RPAREN.getLine());
        }
      } 
      cs=compound_statement
        {
          if($t.name_line.equals("void") && $cs.cs_stmt_line.contains("return")) {
            String errorMsg = "Error at line " +$cs.stop.getLine()+ ": Cannot return value from function "+ $ID.text+ " with void return type \n";
            writeIntoParserLogFile(errorMsg);
            writeIntoErrorFile(errorMsg);
            Main.syntaxErrorCount++;
          }

          $func_def_name=$t.name_line +" "+ $ID.text +"("+ $pl.name_list + ")" + $cs.cs_stmt_line;
          writeIntoParserLogFile(
              "Line " + $cs.stop.getLine() + ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n"
          );
          writeIntoParserLogFile(
              $func_def_name + "\n"
          );

          SymbolInfo func = symbolTable.lookup($ID.text);
          if (func != null) {
            func.setDefined(true);
          }
        }
    | t=type_specifier ID LPAREN RPAREN
      {
        // will need signature and other checking
        if (symbolTable != null) {
            symbolTable.insertFunction($ID.text,$t.name_line,null, $RPAREN.getLine());
        }
      } 
      cs=compound_statement
      {
        if($t.name_line.equals("void") && $cs.cs_stmt_line.contains("return")) {
            String errorMsg = "Error at line " +$cs.stop.getLine()+ ": Cannot return value from function "+ $ID.text+ " with void return type \n";
            writeIntoParserLogFile(errorMsg);
            writeIntoErrorFile(errorMsg);
            Main.syntaxErrorCount++;
        }

        $func_def_name=$t.name_line +" "+ $ID.text +"()" + $cs.cs_stmt_line;
        writeIntoParserLogFile(
            "Line " + $cs.stop.getLine() + ": func_definition : type_specifier ID LPAREN RPAREN compound_statement\n"
        );
        writeIntoParserLogFile(
            $func_def_name + "\n"
        );

        SymbolInfo func = symbolTable.lookup($ID.text);
        if (func != null) {
          func.setDefined(true);
        }
      }
    ;

parameter_list
    returns [String name_list]
    : pl=parameter_list COMMA t=type_specifier ID
      {
        if (symbolTable != null) {
            SymbolInfo param = new SymbolInfo($ID.text, "ID");
            param.setDataType($t.name_line);
            symbolTable.addPendingParameter(param, $ID.getLine()); 
        }

        $name_list = $pl.name_list + $COMMA.text + $t.name_line + " " + $ID.text;
        writeIntoParserLogFile(
            "Line " + $ID.getLine() + ": parameter_list : parameter_list COMMA type_specifier ID\n"
        );
        writeIntoParserLogFile(
            $name_list+"\n"
        );
      }  
    | parameter_list COMMA type_specifier
    | t=type_specifier ID
      {
        if (symbolTable != null) {
            SymbolInfo param = new SymbolInfo($ID.text, "ID");
            param.setDataType($t.name_line);
            symbolTable.addPendingParameter(param, $ID.getLine()); 
        }

        $name_list = $t.name_line + " " + $ID.text;
        writeIntoParserLogFile(
            "Line " + $ID.getLine() + ": parameter_list : type_specifier ID\n"
        );
        writeIntoParserLogFile(
            $name_list + "\n"
        );
      }  
    | type_specifier
    ;

compound_statement
    returns [String cs_stmt_line]
    : LCURL 
      {
        if (symbolTable != null) {
            symbolTable.enterScope();
            symbolTable.insertPendingParameters();
        }
      } 
      st=statements RCURL
      { 
        $cs_stmt_line = "{\n"+$st.stmt+"\n}";
        writeIntoParserLogFile(
            "Line " + $RCURL.getLine() + ": compound_statement : LCURL statements RCURL\n" 
        );
        writeIntoParserLogFile(
            $cs_stmt_line + "\n"
        );

        if (symbolTable != null) {
          symbolTable.exitScope();
        }
      }
    | LCURL
      {
        if (symbolTable != null) {
            symbolTable.enterScope();
            symbolTable.insertPendingParameters();
        }
      } 
      RCURL
      {
        $cs_stmt_line = "{}";
        writeIntoParserLogFile(
            "Line " + $RCURL.getLine() + ": compound_statement : LCURL RCURL\n" 
        );
        writeIntoParserLogFile(
            $cs_stmt_line + "\n"
        );

        if (symbolTable != null) {
          symbolTable.exitScope();
        }
      }
    ;

var_declaration
    returns [String vardec_list]
    : t=type_specifier
      {
        currentVarType = $t.name_line;
      }
      dl=declaration_list sm=SEMICOLON
      {
        $vardec_list = $t.name_line +" "+ $dl.name_list + ";";
        writeIntoParserLogFile(
            "Line " + $sm.getLine() + ": var_declaration : type_specifier declaration_list SEMICOLON\n"
        );

        if($t.name_line.equals("void")){
            String errorMsg = "Error at line " +$sm.getLine()+ ": Variable type cannot be void\n";
            writeIntoParserLogFile(errorMsg);
            writeIntoErrorFile(errorMsg);
            Main.syntaxErrorCount++;
        }

        writeIntoParserLogFile(
            $vardec_list + "\n"
        );

        currentVarType = null;
      }
    | t=type_specifier de=declaration_list_err sm=SEMICOLON
      {
        writeIntoErrorFile(
            "Line# "
            + $sm.getLine()
            + " with error name: "
            + $de.error_name
            + " - Syntax error at declaration list of variable declaration"
        );
        Main.syntaxErrorCount++;
      }
    ;

declaration_list_err
    returns [String error_name]
    : { $error_name = "Error in declaration list"; }
    ;

type_specifier
    returns [String name_line]
    : INT
      {
        $name_line = $INT.text;
        writeIntoParserLogFile(
            "Line " + $INT.line + ": type_specifier : " + "INT\n" 
        );

        writeIntoParserLogFile(
            $INT.text + "\n"
        ); 
      }
    | FLOAT
      {
        $name_line = $FLOAT.text;
        writeIntoParserLogFile(
            "Line " + $FLOAT.line + ": type_specifier : " + "FLOAT\n" 
        );

        writeIntoParserLogFile(
            $FLOAT.text + "\n"
        ); 
      }
    | VOID
      {
        $name_line = $VOID.text;
        writeIntoParserLogFile(
            "Line " + $VOID.line + ": type_specifier : " + "VOID\n" 
        );

        writeIntoParserLogFile(
            $VOID.text + "\n"
        ); 
      }
    ;

declaration_list
    returns [String name_list]
    : dl=declaration_list COMMA ID
      {
        if(symbolTable != null && currentVarType != null) {
            boolean success = symbolTable.insertVariable($ID.text, currentVarType, $ID.line);
            if (!success) {
                Main.syntaxErrorCount++;
            }
        }

        $name_list = $dl.name_list + $COMMA.text + $ID.text;
        writeIntoParserLogFile(
            "Line " + $ID.line +": declaration_list : declaration_list COMMA ID\n"
        );

        writeIntoParserLogFile(
            $name_list + "\n"
        );
      }
    | dl=declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
      {
        if (symbolTable != null && currentVarType != null) {
            int arraySize = Integer.parseInt($CONST_INT.text);
            boolean success = symbolTable.insertArray($ID.text, currentVarType, arraySize, $ID.line);
            if (!success) {
                Main.syntaxErrorCount++;
            }
        }

        $name_list = $dl.name_list + $COMMA.text + $ID.text + "[" + $CONST_INT.text + "]";
        writeIntoParserLogFile(
            "Line " + $RTHIRD.line +": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n"
        );

        writeIntoParserLogFile(
            $name_list + "\n"
        );
      }
    | ID
      {
        if (symbolTable != null && currentVarType != null) {
            boolean success = symbolTable.insertVariable($ID.text, currentVarType, $ID.line);
            if (!success) {
                Main.syntaxErrorCount++;
            }
        }

        $name_list = $ID.text;
        writeIntoParserLogFile(
            "Line " + $ID.line +": declaration_list : ID\n"
        );

        writeIntoParserLogFile(
           $ID.text + "\n" 
        );
      }
    | ID LTHIRD CONST_INT RTHIRD
      {
        if (symbolTable != null && currentVarType != null) {
            int arraySize = Integer.parseInt($CONST_INT.text);
            boolean success = symbolTable.insertArray($ID.text, currentVarType, arraySize, $ID.line);
            if (!success) {
                Main.syntaxErrorCount++;
            }
        }

        $name_list = $ID.text + "[" + $CONST_INT.text + "]";
        writeIntoParserLogFile(
            "Line " + $ID.line +": declaration_list : ID LTHIRD CONST_INT RTHIRD\n"
        );

        writeIntoParserLogFile(
            $name_list + "\n"
        );
      }
    ;

statements
    returns [String stmt]
    : st=statement
      { 
        $stmt = $st.line;
        writeIntoParserLogFile(
            "Line " + $st.stop.getLine() + ": statements : statement\n"
        );
        writeIntoParserLogFile(
            $stmt + "\n"
        );
      }  
    | sts=statements st=statement
      {
        $stmt = $sts.stmt +"\n"+ $st.line;
        writeIntoParserLogFile(
            "Line " + $st.stop.getLine() + ": statements : statements statement\n"
        );
        writeIntoParserLogFile(
            $stmt + "\n"
        );
      }
    ;

statement
    returns [String line]
    : vd=var_declaration
      {
        $line = $vd.vardec_list;
        writeIntoParserLogFile(
            "Line " + $vd.stop.getLine() + ": statement : var_declaration\n"
        );
        writeIntoParserLogFile(
            $line + "\n"
        );
      }
    | exp_st=expression_statement
      {
        $line = $exp_st.exp_stmt;
        writeIntoParserLogFile(
            "Line " + $exp_st.stop.getLine() + ": statement : expression_statement\n"
        );
        writeIntoParserLogFile(
            $line + "\n"
        );
      }
    | cs=compound_statement
      {
        $line = $cs.cs_stmt_line;
        writeIntoParserLogFile(
            "Line " + $cs.stop.getLine() + ": statement : compound_statement\n"
        );
        writeIntoParserLogFile(
            $line + "\n"
        );
      }
    | FOR LPAREN exp_st1=expression_statement exp_st2=expression_statement exp=expression RPAREN st=statement
      {
        $line = "for(" + $exp_st1.exp_stmt + $exp_st2.exp_stmt + $exp.exp_line + ")" + $st.line;
        writeIntoParserLogFile(
            "Line " + $st.stop.getLine() + ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n"
        );
        writeIntoParserLogFile(
            $line + "\n"
        );
      }
    | IF LPAREN exp=expression RPAREN st=statement
      {
        $line = "if" +"("+ $exp.exp_line +")"+ $st.line;
        writeIntoParserLogFile(
            "Line " + $st.stop.getLine() + ": statement : IF LPAREN expression RPAREN statement\n"
        );
        writeIntoParserLogFile(
            $line + "\n"
        );
      }
    | IF LPAREN exp=expression RPAREN st1=statement ELSE st2=statement
      {
        $line = "if" +"("+ $exp.exp_line +")"+ $st1.line + "else " + $st2.line;
        writeIntoParserLogFile(
            "Line " + $st2.stop.getLine() + ": statement : IF LPAREN expression RPAREN statement ELSE statement\n"
        );
        writeIntoParserLogFile(
            $line + "\n"
        );
      }
    | WHILE LPAREN exp=expression RPAREN st=statement
      {
        $line = "while" +"("+ $exp.exp_line +")"+ $st.line;
        writeIntoParserLogFile(
            "Line " + $st.stop.getLine() + ": statement : WHILE LPAREN expression RPAREN statement\n"
        );
        writeIntoParserLogFile(
            $line + "\n"
        );
      }
    | PRINTF LPAREN ID RPAREN sm=SEMICOLON  
      {
        $line = "printf" +"("+ $ID.text +")"+ $sm.text;
        writeIntoParserLogFile(
            "Line " + $sm.getLine() + ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n"
        );
        
        boolean find = symbolTable.isDeclared($ID.text);
        if(!find){
          String errorMsg = "Error at line " + $ID.line + ": Undeclared variable " + $ID.text + "\n";
          writeIntoParserLogFile(errorMsg);
          writeIntoErrorFile(errorMsg);
          Main.syntaxErrorCount++;
        }

        writeIntoParserLogFile(
            $line + "\n"
        );
      }
    | PRINTLN LPAREN ID RPAREN SEMICOLON
    | RETURN exp=expression sm=SEMICOLON
      {
        $line = "return " + $exp.exp_line +";";
        writeIntoParserLogFile(
            "Line " + $sm.getLine() + ": statement : RETURN expression SEMICOLON\n"
        );
        writeIntoParserLogFile(
            $line + "\n"
        );
      }  
    ;

expression_statement
    returns [String exp_stmt]
    : sm=SEMICOLON
      {
        $exp_stmt = $sm.text;
        writeIntoParserLogFile(
          "Line " + $sm.getLine() + ": expression_statement : SEMICOLON\n"
        );
        writeIntoParserLogFile(
            $exp_stmt + "\n"
        );
      }
    | ex=expression sm=SEMICOLON
      {
        $exp_stmt = $ex.exp_line+";";
        writeIntoParserLogFile(
          "Line " + $sm.getLine() + ": expression_statement : expression SEMICOLON\n"
        );
        writeIntoParserLogFile(
            $exp_stmt + "\n"
        );
      }
    ;

variable
    returns [String var, String var_type]
    : ID
      {
        $var = $ID.text;

        writeIntoParserLogFile(
            "Line " + $ID.getLine() + ": variable : ID\n"
        );

        SymbolInfo symbol=null;
        if (symbolTable != null) {
            symbol = symbolTable.lookup($ID.text);
            if (symbol == null) {
                // Variable not declared
                String errorMsg = "Error at line " + $ID.line + ": Undeclared variable " + $ID.text + "\n";
                writeIntoParserLogFile(errorMsg);
                writeIntoErrorFile(errorMsg);
                Main.syntaxErrorCount++;
                $var_type = "error";
            } else {
                $var_type = symbol.getDataType();
            }
        } else {
            $var_type = "unknown";
        }

        if(symbol != null && symbol.isArray()){
            String errorMsg = "Error at line " + $ID.line + ": Type mismatch, " + $ID.text + " is an array\n"; 
            writeIntoParserLogFile(errorMsg);
            writeIntoErrorFile(errorMsg);
            Main.syntaxErrorCount++; 
        }

        writeIntoParserLogFile(
            $var + "\n"
        );
      }
    | ID LTHIRD ex=expression RTHIRD
      {
        $var = $ID.text +"["+ $ex.exp_line + "]";

        writeIntoParserLogFile(
            "Line " + $RTHIRD.getLine() + ": variable : ID LTHIRD expression RTHIRD\n"
        );

        if (symbolTable != null) {
            SymbolInfo arraySymbol = symbolTable.lookup($ID.text);
            if (arraySymbol == null) {
                String errorMsg = "Error at line " + $ID.line + ": Undeclared variable '" + $ID.text + "'";
                writeIntoParserLogFile(errorMsg);
                writeIntoErrorFile(errorMsg);
                Main.syntaxErrorCount++;
                $var_type = "error";
            } else if (!arraySymbol.isArray()) {
                String errorMsg = "Error at line " + $ID.line + ": " + $ID.text + " not an array\n";
                writeIntoParserLogFile(errorMsg);
                writeIntoErrorFile(errorMsg);
                Main.syntaxErrorCount++;
                $var_type = "error";
            } else {
                $var_type = arraySymbol.getDataType();
            }
            
            if (!$ex.exp_type.equals("int")) {
                String errorMsg = "Error at line " + $RTHIRD.line + ": Expression inside third brackets not an integer\n";
                writeIntoParserLogFile(errorMsg);
                writeIntoErrorFile(errorMsg);
                Main.syntaxErrorCount++;
            }
        } else {
            $var_type = "unknown";
        }

        writeIntoParserLogFile(
            $var + "\n"
        );
      }
    ;

expression
    returns [String exp_line, String exp_type]
    : le=logic_expression
      { 
        $exp_line = $le.logi_line;
        $exp_type = $le.logi_type;
        writeIntoParserLogFile(
            "Line " + $le.stop.getLine()+ ": expression : logic_expression\n"
        );
        writeIntoParserLogFile(
            $exp_line + "\n"
        );
      }
    | v=variable ASSIGNOP le=logic_expression
      {
        $exp_line = $v.var+"="+$le.logi_line;
        $exp_type = "int";

        writeIntoParserLogFile(
            "Line " + $le.stop.getLine()+ ": expression : variable ASSIGNOP logic_expression\n"
        );

        checkAssignmentCompatibility($v.var_type, $le.logi_type, $le.stop.getLine());

        writeIntoParserLogFile(
            $exp_line + "\n"
        );
      } 
    ;

logic_expression
    returns [String logi_line, String logi_type]
    : re=rel_expression
      {
        $logi_line = $re.re_line;
        $logi_type = $re.re_type;
        writeIntoParserLogFile(
            "Line " + $re.stop.getLine()+ ": logic_expression : rel_expression\n"
        );
        writeIntoParserLogFile(
            $logi_line + "\n"
        );
      }
    | re1=rel_expression LOGICOP re2=rel_expression
      {
        $logi_line = $re1.re_line + $LOGICOP.text + $re2.re_line;
        $logi_type = "int"; 
        writeIntoParserLogFile(
            "Line " + $re2.stop.getLine()+ ": logic_expression : rel_expression LOGICOP rel_expression\n"
        );
        writeIntoParserLogFile(
            $logi_line + "\n"
        );
      }
    ;

rel_expression
    returns [String re_line, String re_type]
    : se=simple_expression
      {
        $re_line = $se.se_line;
        $re_type = $se.se_type;
        writeIntoParserLogFile(
            "Line " + $se.stop.getLine()+ ": rel_expression : simple_expression\n"
        );
        writeIntoParserLogFile(
            $re_line + "\n"
        );
      }
    | se1=simple_expression RELOP se2=simple_expression
      {
        $re_line = $se1.se_line + $RELOP.text + $se2.se_line;
        $re_type = "int"; 
        writeIntoParserLogFile(
            "Line " + $se2.stop.getLine()+ ": rel_expression : simple_expression RELOP simple_expression\n"
        );
        writeIntoParserLogFile(
            $re_line + "\n"
        );
      }
    ;

simple_expression
    returns [String se_line, String se_type]
    : te=term
      {
        $se_line = $te.term_line;
        $se_type = $te.term_type;
        writeIntoParserLogFile(
            "Line " + $te.stop.getLine()+ ": simple_expression : term\n"
        );
        writeIntoParserLogFile(
            $se_line + "\n"
        );
      }
    | se=simple_expression ADDOP te=term
      { 
        $se_line = $se.se_line + $ADDOP.text + $te.term_line;
        $se_type = determineArithmeticType($se.se_type,$te.term_type);
        writeIntoParserLogFile(
            "Line " + $te.stop.getLine()+ ": simple_expression : simple_expression ADDOP term\n"
        );
        writeIntoParserLogFile(
            $se_line + "\n"
        );
      }  
    ;

term
    returns [String term_line, String term_type]
    : ue=unary_expression
      {
        $term_line = $ue.un_ex_line;
        $term_type = $ue.un_ex_type;
        writeIntoParserLogFile(
            "Line " + $ue.stop.getLine()+ ": term : unary_expression\n"
        );
        writeIntoParserLogFile(
            $term_line + "\n"
        );
      }
    | t=term MULOP ue=unary_expression
      {
        $term_line = $t.term_line + $MULOP.text + $ue.un_ex_line;
        $term_type = determineArithmeticType($t.term_type, $ue.un_ex_type);
        writeIntoParserLogFile(
            "Line " + $ue.stop.getLine()+ ": term : term MULOP unary_expression\n"
        );

        checkVoidInExpression($t.term_type,$ue.un_ex_type, $MULOP.line);

        if($MULOP.text.equals("%")){
            if($term_type.equals("float")) {
              String errorMsg = "Error at line " + $ue.stop.getLine() +": Non-Integer operand on modulus operator\n";
              writeIntoParserLogFile(errorMsg);
              writeIntoErrorFile(errorMsg);
              Main.syntaxErrorCount++;
              $term_type = "int";
            }
            else if($ue.un_ex_line.equals("0")) {
              String errorMsg = "Error at line " + $ue.stop.getLine() +": Modulus by Zero\n";
              writeIntoParserLogFile(errorMsg);
              writeIntoErrorFile(errorMsg);
              Main.syntaxErrorCount++;
              $term_type = "int";
            }
        }

        writeIntoParserLogFile(
            $term_line + "\n"
        );
      }
    ;

unary_expression
    returns [String un_ex_line, String un_ex_type]
    : ADDOP un=unary_expression
      {
        $un_ex_line = $ADDOP.text + $un.un_ex_line;
        $un_ex_type = $un.un_ex_type;
        writeIntoParserLogFile(
            "Line " + $un.stop.getLine()+ ": unary_expression : ADDOP unary_expression\n"
        );
        writeIntoParserLogFile(
            $un_ex_line + "\n"
        );
      }
    | NOT un=unary_expression
      {
        $un_ex_line = $NOT.text + $un.un_ex_line;
        $un_ex_type = $un.un_ex_type;
        writeIntoParserLogFile(
            "Line " + $un.stop.getLine()+ ": unary_expression : NOT unary_expression\n"
        );
        writeIntoParserLogFile(
            $un_ex_line + "\n"
        );
      }
    | f=factor
      { 
        $un_ex_line = $f.ft_line;
        $un_ex_type = $f.ft_type;
        writeIntoParserLogFile(
            "Line " + $f.stop.getLine()+ ": unary_expression : factor\n"
        );
        writeIntoParserLogFile(
            $un_ex_line + "\n"
        );
      }  
    ;

factor
    returns [String ft_line, String ft_type]
    : v=variable
      { 
        $ft_line = $v.var;
        $ft_type = $v.var_type;
        writeIntoParserLogFile(
            "Line " + $v.stop.getLine()+ ": factor : variable\n"
        );
        writeIntoParserLogFile(
            $ft_line + "\n"
        );
      }  
    | ID LPAREN argl=argument_list RPAREN
      {
        //this is a function. So we need to check arguments
        $ft_line = $ID.text +"("+ $argl.arg_list +")";
        $ft_type = getFunctionReturnType($ID.text, $ID.line);

        writeIntoParserLogFile(
            "Line " + $RPAREN.getLine()+ ": factor : ID LPAREN argument_list RPAREN\n"
        );

        if (symbolTable != null && $argl.arg_types != null) {
            checkFunctionCall($ID.text, $argl.arg_types, $ID.line);
        }

        writeIntoParserLogFile(
            $ft_line + "\n"
        );
      }
    | LPAREN ex=expression RPAREN
      {
        $ft_line = "(" + $ex.exp_line + ")" ;
        $ft_type = $ex.exp_type;
        writeIntoParserLogFile(
            "Line " + $RPAREN.getLine()+ ": factor : LPAREN expression RPAREN\n"
        );
        writeIntoParserLogFile(
            $ft_line + "\n"
        );
      }
    | ci=CONST_INT
      {
        $ft_line = $ci.text;
        $ft_type = "int";
        writeIntoParserLogFile(
            "Line " + $ci.getLine() + ": factor : CONST_INT\n"
        );
        writeIntoParserLogFile(
            $ft_line + "\n"
        );
      }
    | cf=CONST_FLOAT
      {
        $ft_line = $cf.text;
        $ft_type = "float";
        writeIntoParserLogFile(
            "Line " + $cf.getLine() + ": factor : CONST_FLOAT\n"
        );
        writeIntoParserLogFile(
            $ft_line + "\n"
        );
      }
    | v=variable INCOP
      {
        $ft_line = $v.var + $INCOP.text;
        $ft_type = $v.var_type;
        writeIntoParserLogFile(
            "Line " + $v.stop.getLine()+ ": factor : variable INCOP\n"
        );
        writeIntoParserLogFile(
            $ft_line + "\n"
        );
      }
    | v=variable DECOP
      {
        $ft_line = $v.var + $DECOP.text;
        $ft_type = $v.var_type;
        writeIntoParserLogFile(
            "Line " + $v.stop.getLine()+ ": factor : variable DECOP\n"
        );
        writeIntoParserLogFile(
            $ft_line + "\n"
        );
      }
    ;

argument_list
    returns [String arg_list, List<String> arg_types]
    : args=arguments
      {
        $arg_list = $args.arg_line;  
        $arg_types = $args.arg_type_list;
        writeIntoParserLogFile(
            "Line " + $args.stop.getLine() + ": argument_list : arguments\n"
        );
        writeIntoParserLogFile(
            $arg_list + "\n"
        );
      }
    | /* empty */
      {
        $arg_list = "";
        $arg_types = new ArrayList<String>();
      }
    ;

arguments
    returns [String arg_line, List<String> arg_type_list]
    : args=arguments COMMA le=logic_expression
      {
        $arg_line = $args.arg_line +","+ $le.logi_line;
        $arg_type_list = new ArrayList<>($args.arg_type_list);
        $arg_type_list.add($le.logi_type);

        writeIntoParserLogFile(
            "Line " + $COMMA.getLine() + ": arguments : arguments COMMA logic_expression\n"
        );
        writeIntoParserLogFile(
            $arg_line + "\n"
        );
      }
    | le=logic_expression
      {
        $arg_line = $le.logi_line;
        $arg_type_list = new ArrayList<String>();
        $arg_type_list.add($le.logi_type);

        writeIntoParserLogFile(
            "Line " + $le.stop.getLine() + ": arguments : logic_expression\n"
        );
        writeIntoParserLogFile(
            $arg_line + "\n"
        );
      }
    ;
