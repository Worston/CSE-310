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
            if (var.contains("[") && var.contains("]")) {
                String[] parts = var.split("\\[");
                String arrayName = parts[0].trim();
                String sizePart = parts[1].replace("]", "").trim();
                
                int arraySize = sizePart.isEmpty() ? -1 : parseArraySize(sizePart);
                symbolTable.insertArray(arrayName, type, arraySize);
            } else {
                symbolTable.insertVariable(var, type);
            }
        }
    }

    private int parseArraySize(String sizeStr) {
        if (sizeStr.isEmpty()) {
            return -1; // Unspecified size
        }
        
        try {
            return Integer.parseInt(sizeStr);
        } catch (NumberFormatException e) {
            // Size is a variable/expression like 'n' or 'MAX_SIZE'
            // For semantic analysis, we might want to look it up
            // For now, return -1 to indicate dynamic/unknown size
            return -1;
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
          symbolTable.insertFunction($ID.text, $t.name_line, params);
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

          SymbolInfo func = symbolTable.lookup($ID.text);
          if (func != null) {
            func.setDefined(true);
          }
        }
    | t=type_specifier ID LPAREN RPAREN
      {
        // will need signature and other checking
        if (symbolTable != null) {
            symbolTable.insertFunction($ID.text,$t.name_line,null);
        }
      } 
      cs=compound_statement
      {
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
    | dl=declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
      {
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
    | ID LTHIRD ex=expression RTHIRD
      {
        $var = $ID.text +"["+ $ex.exp_line + "]";
        writeIntoParserLogFile(
            "Line " + $RTHIRD.getLine() + ": variable : ID LTHIRD expression RTHIRD\n"
        );
        writeIntoParserLogFile(
            $var + "\n"
        );
      }
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
    | v=variable ASSIGNOP le=logic_expression
      {
        $exp_line = $v.var+"="+$le.logi_line;
        writeIntoParserLogFile(
            "Line " + $le.stop.getLine()+ ": expression : variable ASSIGNOP logic_expression\n"
        );
        writeIntoParserLogFile(
            $exp_line + "\n"
        );
      } 
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
    | re1=rel_expression LOGICOP re2=rel_expression
      {
        $logi_line = $re1.re_line + $LOGICOP.text + $re2.re_line;
        writeIntoParserLogFile(
            "Line " + $re2.stop.getLine()+ ": logic_expression : rel_expression LOGICOP rel_expression\n"
        );
        writeIntoParserLogFile(
            $logi_line + "\n"
        );
      }
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
    | se1=simple_expression RELOP se2=simple_expression
      {
        $re_line = $se1.se_line + $RELOP.text + $se2.se_line;
        writeIntoParserLogFile(
            "Line " + $se2.stop.getLine()+ ": rel_expression : simple_expression RELOP simple_expression\n"
        );
        writeIntoParserLogFile(
            $re_line + "\n"
        );
      }
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
    | t=term MULOP ue=unary_expression
      {
        $term_line = $t.term_line + $MULOP.text + $ue.un_ex_line;
        writeIntoParserLogFile(
            "Line " + $ue.stop.getLine()+ ": term : term MULOP unary_expression\n"
        );
        writeIntoParserLogFile(
            $term_line + "\n"
        );
      }
    ;

unary_expression
    returns [String un_ex_line]
    : ADDOP un=unary_expression
      {
        $un_ex_line = $ADDOP.text + $un.un_ex_line;
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
    | ID LPAREN argl=argument_list RPAREN
      {
        $ft_line = $ID.text +"("+ $argl.arg_list +")";
        writeIntoParserLogFile(
            "Line " + $RPAREN.getLine()+ ": factor : ID LPAREN argument_list RPAREN\n"
        );
        writeIntoParserLogFile(
            $ft_line + "\n"
        );
      }
    | LPAREN ex=expression RPAREN
      {
        $ft_line = "(" + $ex.exp_line + ")" ;
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
        writeIntoParserLogFile(
            "Line " + $v.stop.getLine()+ ": factor : variable DECOP\n"
        );
        writeIntoParserLogFile(
            $ft_line + "\n"
        );
      }
    ;

argument_list
    returns [String arg_list]
    : args=arguments
      {
        $arg_list = $args.arg_line;  
        writeIntoParserLogFile(
            "Line " + $args.stop.getLine() + ": argument_list : arguments\n"
        );
        writeIntoParserLogFile(
            $arg_list + "\n"
        );
      }
    | /* empty */
    ;

arguments
    returns [String arg_line]
    : args=arguments COMMA le=logic_expression
      {
        $arg_line = $args.arg_line +","+ $le.logi_line;
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
        writeIntoParserLogFile(
            "Line " + $le.stop.getLine() + ": arguments : logic_expression\n"
        );
        writeIntoParserLogFile(
            $arg_line + "\n"
        );
      }
    ;
