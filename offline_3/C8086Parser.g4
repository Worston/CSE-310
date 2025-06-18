parser grammar C8086Parser;

options {
    tokenVocab = C8086Lexer;
}

@header {
import java.io.BufferedWriter;
import java.io.IOException;
}

@members {
    private SymbolTable symbolTable;
    
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

    void insertVariablesFromDeclarationList(String type, String declarationList) {
        if (symbolTable == null) return;
        
        String[] vars = declarationList.split(",");
        for (String var : vars) {
            var = var.trim();
            if (var.contains("[")) {
                // Handle array declaration
                String name = var.substring(0, var.indexOf("["));
                SymbolInfo symbol = new SymbolInfo(name.trim(), "ID");
                symbol.setDataType(type);
                symbol.setArray(true);
                symbolTable.insert(symbol);
            } else {
                SymbolInfo symbol = new SymbolInfo(var, "ID");
                symbol.setDataType(type);
                symbolTable.insert(symbol);
            }
        }
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
            "Total lines: " + $program.stop.getLine() + "\n"
            + "Total errors: " + Main.syntaxErrorCount + "\n"
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
    : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
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
            SymbolInfo func = new SymbolInfo($ID.text, "ID");
            func.setDataType($t.name_line);
            func.setFunction(true);
            symbolTable.insert(func);
        }
      }
    ;

func_definition
    returns [String func_def_name]
    : t=type_specifier ID LPAREN pl=parameter_list RPAREN 
      { 
        if (symbolTable != null) {
          SymbolInfo func = new SymbolInfo($ID.text, "ID");
          func.setDataType($t.name_line);
          func.setFunction(true);
          symbolTable.insert(func);
        }
      } 
      cs=compound_statement
        {
          $func_def_name=$t.name_line +" "+ $ID.text +"("+ $pl.name_list + ")" + $cs.cs_stmt_line;
          writeIntoParserLogFile(
              "Line " + $cs.stop.getLine() + ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n"
          );
          writeIntoParserLogFile(
              $func_def_name + "\n"
          );
        }
    | type_specifier ID LPAREN RPAREN compound_statement
    ;

parameter_list
    returns [String name_list]
    : pl=parameter_list COMMA t=type_specifier ID
      {
        $name_list = $pl.name_list + $COMMA.text + $t.name_line + " " + $ID.text;
        writeIntoParserLogFile(
            "Line " + $ID.getLine() + ": parameter_list : parameter_list COMMA type_specifier ID\n"
        );
        writeIntoParserLogFile(
            $name_list+"\n"
        );

        if (symbolTable != null) {
            SymbolInfo param = new SymbolInfo($ID.text, "ID");
            param.setDataType($t.name_line);
            //symbolTable.insert(param);
            symbolTable.addPendingParameter(param); 
        }
      }  
    | parameter_list COMMA type_specifier
    | t=type_specifier ID
      {
        $name_list = $t.name_line + " " + $ID.text;
        writeIntoParserLogFile(
            "Line " + $ID.getLine() + ": parameter_list : type_specifier ID\n"
        );
        writeIntoParserLogFile(
            $name_list + "\n"
        );

        if (symbolTable != null) {
            SymbolInfo param = new SymbolInfo($ID.text, "ID");
            param.setDataType($t.name_line);
            //symbolTable.insert(param);
            symbolTable.addPendingParameter(param); 
        }
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
            // "{\n"+$st.stmt+"}\n"
            $cs_stmt_line + "\n"
        );

        if (symbolTable != null) {
          symbolTable.exitScope();
        }
      
      }
    | LCURL RCURL
    ;

var_declaration
    returns [String vardec_list]
    : t=type_specifier dl=declaration_list sm=SEMICOLON
      {
        $vardec_list = $t.name_line +" "+ $dl.name_list + ";";
        writeIntoParserLogFile(
            "Line " + $sm.getLine() + ": var_declaration : type_specifier declaration_list SEMICOLON\n"
        );
        writeIntoParserLogFile(
            $vardec_list + "\n"
        );

        insertVariablesFromDeclarationList($t.name_line, $dl.name_list);
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
        $name_list = $dl.name_list + $COMMA.text + $ID.text;
        writeIntoParserLogFile(
            "Line " + $ID.line +": declaration_list : declaration_list COMMA ID\n"
        );

        writeIntoParserLogFile(
            $name_list + "\n"
        );
      }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    | ID
      {
        $name_list = $ID.text;
        writeIntoParserLogFile(
            "Line " + $ID.line +": declaration_list : ID\n"
        );

        writeIntoParserLogFile(
           $ID.text + "\n" 
        );
      }
    | ID LTHIRD CONST_INT RTHIRD
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
    | statements statement
    ;

statement
    returns [String line]
    : var_declaration
    | expression_statement
    | compound_statement
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement
    | IF LPAREN expression RPAREN statement
    | IF LPAREN expression RPAREN statement ELSE statement
    | WHILE LPAREN expression RPAREN statement
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
    : SEMICOLON
    | expression SEMICOLON
    ;

variable
    returns [String var]
    : ID
      {
        $var = $ID.text;
        writeIntoParserLogFile(
            "Line " + $ID.getLine() + ": variable : ID\n"
        );
        writeIntoParserLogFile(
            $var + "\n"
        );
      }
    | ID LTHIRD expression RTHIRD
    ;

expression
    returns [String exp_line]
    : le=logic_expression
      { 
        $exp_line = $le.logi_line;
        writeIntoParserLogFile(
            "Line " + $le.stop.getLine()+ ": expression : logic_expression\n"
        );
        writeIntoParserLogFile(
            $exp_line + "\n"
        );
      }
    | variable ASSIGNOP logic_expression
    ;

logic_expression
    returns [String logi_line]
    : re=rel_expression
      {
        $logi_line = $re.re_line;
        writeIntoParserLogFile(
            "Line " + $re.stop.getLine()+ ": logic_expression : rel_expression\n"
        );
        writeIntoParserLogFile(
            $logi_line + "\n"
        );
      }
    | rel_expression LOGICOP rel_expression
    ;

rel_expression
    returns [String re_line]
    : se=simple_expression
      {
        $re_line = $se.se_line;
        writeIntoParserLogFile(
            "Line " + $se.stop.getLine()+ ": rel_expression : simple_expression\n"
        );
        writeIntoParserLogFile(
            $re_line + "\n"
        );
      }
    | simple_expression RELOP simple_expression
    ;

simple_expression
    returns [String se_line]
    : te=term
      {
        $se_line = $te.term_line;
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
        writeIntoParserLogFile(
            "Line " + $te.stop.getLine()+ ": simple_expression : simple_expression ADDOP term\n"
        );
        writeIntoParserLogFile(
            $se_line + "\n"
        );
      }  
    ;

term
    returns [String term_line]
    : ue=unary_expression
      {
        $term_line = $ue.un_ex_line;
        writeIntoParserLogFile(
            "Line " + $ue.stop.getLine()+ ": term : unary_expression\n"
        );
        writeIntoParserLogFile(
            $term_line + "\n"
        );
      }
    | term MULOP unary_expression
    ;

unary_expression
    returns [String un_ex_line]
    : ADDOP unary_expression
    | NOT unary_expression
    | f=factor
      { 
        $un_ex_line = $f.ft_line;
        writeIntoParserLogFile(
            "Line " + $f.stop.getLine()+ ": unary_expression : factor\n"
        );
        writeIntoParserLogFile(
            $un_ex_line + "\n"
        );
      }  
    ;

factor
    returns [String ft_line]
    : v=variable
      { 
        $ft_line = $v.var;
        writeIntoParserLogFile(
            "Line " + $v.stop.getLine()+ ": factor : variable\n"
        );
        writeIntoParserLogFile(
            $ft_line + "\n"
        );
      }  
    | ID LPAREN argument_list RPAREN
    | LPAREN expression RPAREN
    | CONST_INT
    | CONST_FLOAT
    | variable INCOP
    | variable DECOP
    ;

argument_list
    : arguments
    | /* empty */
    ;

arguments
    : arguments COMMA logic_expression
    | logic_expression
    ;
