%option noyywrap yylineno
%x SINGLESTRING
%x MULTISTRING
%x SINGLECMNT
%x MULTICMNT

%{
#include <iostream>
#include <fstream>
#include <string>
#include <cstring>
#include "SymbolTable.hpp"
using namespace std;

ofstream log_file;
ofstream token_file;
int line_count = 1;
int error_count = 0;
int cmnt_lineno;
bool undef_escape_character;
string output;
string cmnt_str;

SymbolTable st(7);

char getASCIIChar(char ch) {
	switch(ch) {
		case '\\': return ch;
		case '\"': return ch;
		case '\'': return ch;
		case 'n' : return '\n';
		case 't' : return '\t';
		case 'a' : return '\a';
		case 'f' : return '\f';
		case 'r' : return '\r';
		case 'b' : return '\b';
		case 'v' : return '\v';
		case '0' : return '\0';
		default:
			return -1;
	}
}

string to_upper(const string& str) {
    string result = str;
    for (char& c : result)
        c = toupper(static_cast<unsigned char>(c));
    return result;
}

string processEscapeString(const string& input) {
	string result;

	for (size_t i = 0; i < input.length(); ++i) {
		if (input[i] == '\\' && i + 1 < input.length()) {
			char escaped = getASCIIChar(input[i + 1]);

			if (escaped == '\b') {
				if (result.length() >= 2)
					result.erase(result.end() - 2, result.end());
				i++; 
				continue;
			}

			result.push_back(escaped);
			i++; 
		} else {
			result.push_back(input[i]);
		}
	}
	return result;
}

string processStringMultiline(const string& source) {
    string result;
    int n = source.length();

	for (int i = 1; i < n - 1; ++i) { 
        if (source[i] == '\\') {
            // Backslash-newline continuation
            if (i + 1 < n && source[i + 1] == '\n') {
				//result += '\t';  
                i += 2; 
                continue;
            }
            // Other escape sequences
            else if (i + 1 < n) {
                char c = getASCIIChar(source[i + 1]);
                if (c == '\b') {
                    if (result.size() >= 2) result.erase(result.end() - 2, result.end());
                    i++;  
                    continue;
                }
                result += c;
                i++;  
            }
        } else {
            result += source[i];
        }
    }

    return result;
}

void processConstChar(const string& lexeme) {
    string content = lexeme.substr(1, lexeme.length() - 2);

    char actual_char = content.empty() ? '\0' : content[0];
    string display_str = content;

    if (!content.empty() && content[0] == '\\') {
        actual_char = getASCIIChar(content[1]);
        display_str = "\\" + string(1, content[1]);
    }

    // Token file writes ACTUAL CHARACTER
    token_file << "<CONST_CHAR, " << actual_char << "> ";

    // Log file shows ESCAPED REPRESENTATION
    log_file << "Line# " << yylineno << ": Token <CONST_CHAR> Lexeme '" 
            << display_str << "' found --> <CONST_CHAR, " 
            << actual_char << ">\n\n";

    // Symbol table insertion with ACTUAL CHARACTER
    //string value(1, actual_char);
    if (st.insert(/*value*/display_str, "CONST_CHAR")) {
        st.printAllScope();
        log_file << "\n";
    }
}

void push_to_table(const string& type, const string& name) {
	token_file << "<"<< type <<", " << name << "> ";
	log_file << "Line# " << yylineno <<": Token <ID> Lexeme " << name << " found\n\n";
	if(st.insert(name,type)){
		st.printAllScope();
		log_file << "\n";
	}
}
%}

WHITESPACE      [ \t\r\f\v]+
ID 		  		[A-Za-z_][A-Za-z0-9_]*
KEYWORD	  	    "if"|"do"|"float"|"switch"|"for"|"int"|"long"|"short"|"static"|"void"|"default"|"else"|"break"|"double"|"case"|"while"|"char"|"return"|"continue"|"goto"|"unsigned"
NEWLINE   	    "\n"|"\r\n"
ADDOP    	    "+"|"-"
MULOP    	    "*"|"/"|"%"
INCOP   	    "++"|"--"
RELOP    	    "<"|"<="|">"|">="|"=="|"!="
ASSIGNOP  	    "="
LOGICOP  	    "&&"|"||"
NOT     	    "!"
LPAREN   	    "("
RPAREN   	    ")"
LCURL   	    "{"
RCURL   	    "}"
LTHIRD          "["
RTHIRD   	    "]"
COMMA           ","
SEMICOLON       ";"
DIGIT           [0-9]+
CONSTFLOAT      {DIGIT}+(\.{DIGIT}+)?[Ee][+-]?{DIGIT}+|{DIGIT}*(\.{DIGIT}+)|{DIGIT}+\.
CONSTCHAR       \'([^'"\\\n]|\\[ntafrbv0\\'"])\'
STRINGBODY      ([^'"\\\n]|\\[ntafrbv0\\'"])*
UNDFSCAPE       (\\[^ntafrbv0\\'"])
UNRECCONSTCHAR  \'{UNDFSCAPE}\'
%%

{WHITESPACE} {}

{NEWLINE} { line_count++; }

{KEYWORD} {
		token_file << "<" << to_upper(string(yytext)) << "> ";
		log_file << "Line# " << yylineno <<": Token <" << to_upper(string(yytext)) << ">" << " Lexeme found\n\n";
	}

{ADDOP} {
		token_file << "<ADDOP, " << yytext << "> ";
		log_file << "Line# " << yylineno <<": Token <ADDOP> Lexeme " << yytext << " found\n\n";
	}	

{MULOP} {
		token_file << "<MULOP, " << yytext << "> ";
		log_file << "Line# " << yylineno <<": Token <MULOP> Lexeme " << yytext << " found\n\n";
	}

{INCOP} {
		token_file << "<INCOP, " << yytext << "> ";
		log_file << "Line# " << yylineno <<": Token <INCOP> Lexeme " << yytext << " found\n\n";
	}	

{RELOP} {
		token_file << "<RELOP, " << yytext << "> ";
		log_file << "Line# " << yylineno <<": Token <RELOP> Lexeme " << yytext << " found\n\n";
	}

{ASSIGNOP} {
		token_file << "<ASSIGNOP, " << yytext << "> ";
		log_file << "Line# " << yylineno <<": Token <ASSIGNOP> Lexeme " << yytext << " found\n\n";
	}

{LOGICOP} {
		token_file << "<LOGICOP, " << yytext << "> ";
		log_file << "Line# " << yylineno <<": Token <LOGICOP> Lexeme " << yytext << " found\n\n";
	}	

{NOT} {
		token_file << "<NOT, " << yytext << "> ";
		log_file << "Line# " << yylineno <<": Token <NOT> Lexeme " << yytext << " found\n\n";
	}

{LPAREN} {
		token_file << "<LPAREN, " << yytext << "> ";
		log_file << "Line# " << yylineno <<": Token <LPAREN> Lexeme " << yytext << " found\n\n";
	}

{RPAREN} {
		token_file << "<RPAREN, " << yytext << "> ";
		log_file << "Line# " << yylineno <<": Token <RPAREN> Lexeme " << yytext << " found\n\n";
	}	

{LCURL} {
		token_file << "<LCURL, " << yytext << "> ";
		log_file << "Line# " << yylineno <<": Token <LCURL> Lexeme " << yytext << " found\n\n";
		st.enterScope();
	}

{RCURL} {
		token_file << "<RCURL, " << yytext << "> ";
		log_file << "Line# " << yylineno <<": Token <RCURL> Lexeme " << yytext << " found\n\n";
		st.exitScope();
	}	

{LTHIRD} {
		token_file << "<LTHIRD, " << yytext << "> ";
		log_file << "Line# " << yylineno <<": Token <LTHIRD> Lexeme " << yytext << " found\n\n";
	}

{RTHIRD} {
		token_file << "<RTHIRD, " << yytext << "> ";
		log_file << "Line# " << yylineno <<": Token <RTHIRD> Lexeme " << yytext << " found\n\n";
	}

{COMMA} {
		token_file << "<COMMA, " << yytext << "> ";
		log_file << "Line# " << yylineno<<": Token <COMMA> Lexeme " << yytext << " found\n\n";
	}	

{SEMICOLON} {
		token_file << "<SEMICOLON, " << yytext << "> ";
		log_file << "Line# " << yylineno <<": Token <SEMICOLON> Lexeme " << yytext << " found\n\n";
	}	

{CONSTCHAR} {
		string lexeme = yytext;
		processConstChar(lexeme);
	}	

{DIGIT} {
		string type("CONST_INT");
		string name(yytext);
		push_to_table(type, name);
	}

{CONSTFLOAT} {
		string type("CONST_FLOAT");
		string name(yytext);
		push_to_table(type, name); 
	}	

{ID} {
		string type("ID");
		string name(yytext);
		push_to_table(type, name);
	}

\"{STRINGBODY} {
		output = string(yytext);
		undef_escape_character = false;
		BEGIN(SINGLESTRING);
	}

<SINGLESTRING>{STRINGBODY}\" {
		output += string(yytext);
		string formatted = processEscapeString(output.substr(1, output.length()-2));
		if(undef_escape_character) {
			//error will handle later
		} else {
			token_file << "<STRING, " << formatted << "> ";
			log_file << "Line# " << yylineno <<": Token <STRING> Lexeme " <<
			output << " found --> <STRING, " << formatted << ">\n\n"; 
		}
		BEGIN(INITIAL);
	}

<SINGLESTRING>{STRINGBODY}\\\n {
		output += string(yytext);
		BEGIN(MULTISTRING);   // "This is a string \ 
							  // Continuing here"
	}	

<SINGLESTRING>{STRINGBODY}[\n] {
		//error here will handle later
		BEGIN(INITIAL);
	}

<SINGLESTRING>(({STRINGBODY})({UNDFSCAPE}+)) {
		output += string(yytext);
		undef_escape_character = true;
	}	

<SINGLESTRING><<EOF>> {
		//error here
		BEGIN(INITIAL);
	}

<MULTISTRING>{STRINGBODY}\\\n {
		output += string(yytext);
		BEGIN(MULTISTRING);
	}

<MULTISTRING>{STRINGBODY}\" {
		output += string(yytext);
		string formatted = processStringMultiline(output);
		if(undef_escape_character) {
			// error here will handle later

		} else {
			token_file << "<STRING, " << formatted << "> ";
    		log_file << "Line# " << yylineno << ": Token <STRING> Lexeme " 
            << output << " found --> <STRING, " << formatted << ">\n\n";
		}
		BEGIN(INITIAL);
	}

<MULTISTRING>{STRINGBODY}[\n] {
	  	// error here will handle later
		BEGIN(INITIAL);
	}	

<MULTISTRING>(({STRINGBODY})({UNDFSCAPE}+)) {
		output += string(yytext);
		undef_escape_character = true;
	}

<MULTISTRING><<EOF>> {
		//error here
		BEGIN(INITIAL);
	}

"//" {
		cmnt_str += yytext;
		cmnt_lineno = yylineno;
		BEGIN(SINGLECMNT);
	}

<SINGLECMNT>{NEWLINE} {}

<SINGLECMNT>^{WHITESPACE} {}

<SINGLECMNT>.*\\$ {
		cmnt_str += string(yytext) + "\n"; 
		BEGIN(SINGLECMNT);
	}

<SINGLECMNT>.* {
		cmnt_str += string(yytext) ;
		BEGIN(INITIAL); 
		log_file << "Line# " << cmnt_lineno <<": Token <COMMENT> Lexeme " << cmnt_str << " found\n\n";
		cmnt_str.clear();
	}

<SINGLECMNT><<EOF>> {
		//error here will handle later
		cmnt_str.clear();
		BEGIN(INITIAL);
	}

%%

int main(int argc, char *argv[]){

    if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}

	string student_id = "2105015";
	token_file.open(student_id + "_token.txt");
	log_file.open(student_id + "_log.txt");

	ScopeTable::setOutputStream(&log_file);

	yyin= fin;
	yylex();

	log_file << "Total lines: " << yylineno << "\n";
	log_file << "Total errors: " << error_count << "\n";

	fclose(yyin);
	token_file.close();
	log_file.close();
	return 0;
}



	// string actual_char = lexeme.substr(1, lexeme.length() - 2);

	// bool is_escaped = (content.size() >= 1 && content[0] == '\\');

	// bool _if_escaped = isEscaped(actual_char);
	// actual_char = processChar(actual_char);
	// string display = actual_char;

	// token_file << "<CONST_CHAR, " << actual_char << "> ";
	// if (_if_escaped) display = "\\" + display;
	// log_file <<"Line# "<< line_count << ": Token <CONST_CHAR> Lexeme '"  << display << 
	// "' found  --> <CONST_CHAR, " << actual_char << ">\n\n";