#include<bits/stdc++.h>
#include"SymbolTable.hpp"
#include"Hashfunctions.hpp"
using namespace std;

#define MAX_ARGS 100
#define MAX_FIELDS 50

string trim(const string& str){
    int first_letter = str.find_first_not_of(" \t");
    if (first_letter == string::npos){
        return "";
    }
    int last_letter = str.find_last_not_of(" \t");
    return str.substr(first_letter, (last_letter-first_letter+1));
}

string formatType(const string& baseType, istringstream& ss){
    string params;
    getline(ss,params);
    params = trim(params);

    // cases started
    if (baseType == "FUNCTION"){
        string args[MAX_ARGS];
        int argCount = 0;

        istringstream iss(params);
        string returnType;
        iss >> returnType;

        while (iss >> args[argCount] && argCount < MAX_ARGS-1){
           argCount++;
        }

        string formatted = "FUNCTION," + returnType + "<==(";
        for (size_t i = 0; i < argCount; i++){
            if (i > 0){
                formatted += ",";
            }
            formatted += args[i];
        }
        formatted += ")";
        return formatted;
    }

    else if (baseType == "STRUCT" || baseType == "UNION"){
        string fields[MAX_FIELDS];
        int fieldCount = 0;

        istringstream iss(params);
        string type, name;

        while (iss >> type >> name && fieldCount < MAX_FIELDS-1){
            fields[fieldCount] = "(" + type + "," + name + ")";
            fieldCount++;
        }

        string formatted = baseType + ",{";
        for (size_t i = 0; i < fieldCount; i++){
            if (i > 0){
                formatted += ",";
            }
            formatted += fields[i];
        }
        formatted += "}";
        return formatted;
    }

    else
        return baseType + (params.empty()? "": ","+ params);
}

void processLine(const string& line, SymbolTable& st, ostream& out, int cmdCount){
    istringstream ss(line);
    string cmd;
    ss >> cmd;

    stringstream buffer;

    try {
        if (cmd == "I"){
            string name, baseType;
            if (!(ss >> name >> baseType)){
                // buffer << "Number of parameters mismatch for command I\n";
                throw runtime_error("Number of parameters mismatch for command I");
            } 

            bool isComplex = (baseType == "FUNCTION" || baseType == "STRUCT" || baseType == "UNION");
            string remaining;
            getline(ss, remaining);
            remaining = trim(remaining);

            if (!isComplex && !remaining.empty()){
                throw runtime_error("Number of parameters mismatch for command I");
            }

            istringstream paramStream(remaining);
            string formattedType = formatType(baseType, paramStream);
            
            if (!st.insert(name, formattedType)) {
                buffer << "\t'" << name << "' already exists in the current Scopetable\n";
            }
        }

        else if (cmd == "L"){
            string name;
            if (!(ss >> name)){
                //buffer << "Number of parameters mismatch for command L\n";
                throw runtime_error("Number of parameters mismatch for command L");
            }
            
            string extra;
            if(ss >> extra) {
                throw runtime_error("Number of parameters mismatch for command L");
            }
            
            SymbolInfo* result = st.lookup(name);
            if(!result) buffer<<"\t'"<<name<<"' not found in any of the ScopeTables\n";
        }
        
        else if (cmd == "D"){
            string name;
            if (!(ss >> name)){
                throw runtime_error("Number of parameters mismatch for command D");
            }
            
            string extra;
            if(ss >> extra) {
                throw runtime_error("Number of parameters mismatch for command D");
            }
            
            
            if(!st.remove(name)){ //handle buffer later
                buffer << "\tNot found in current ScopeTable\n";
            }
        }

        else if (cmd == "P"){
            char mode;
            if (!(ss >> mode) || (mode != 'A' && mode != 'C')){
                // buffer << "Invalid print mode\n";
                throw runtime_error("Invalid print mode.");
            }
            if(mode == 'C') st.printCurrentScope();
            else st.printAllScope();
        }
        
        else if (cmd == "S") st.enterScope();
        else if (cmd == "E") st.exitScope();
        else if (cmd == "Q") {
            st.~SymbolTable();
            exit(0);
        } // we need to call the destructor of the symbol table here
        else throw runtime_error("Invalid command");
    } catch(const exception& e){
        buffer << "\t" << e.what() << "\n";
    }
    
    string outputLine;
    while (getline(buffer, outputLine)){
        if (!outputLine.empty()) {
            out << "\t" << outputLine << "\n";
            out.flush();
        }
    }
}

int main(int argc, char const *argv[]){
    cout<<"Running fine\n";

    if (argc < 3){
        cerr << "Usage: " << argv[0] << " <input_file> <output_file> [hash_function]\n";
        return 1;
    }

    string hashfunc;
    if (argc >= 4){
        hashfunc = trim(argv[3]);
        if (hashfunc == "" || hashfunc == "SDBM"){
            hashfunc = "SDBM";
        }
        // implement else logic here.
    }

    SymbolTable::setHashFunction(SDBMHash); 
    
    //file handling
    ifstream infile(argv[1]);
    ofstream outfile(argv[2]);

    if (!infile || !outfile){
        cerr << "Error opening files!\n";
        return 1;
    }

    SymbolTable::setOutputStream(&outfile);
    ScopeTable::setOutputStream(&outfile);

    string line;
    getline(infile, line);
    int numBuckets = stoi(trim(line));

    SymbolTable st(numBuckets);
    int cmdCount = 0;

    // processing commands
    while (getline(infile, line)) {
        line = trim(line);
        if (line.empty()) continue;
        cmdCount++;
        outfile << "Cmd " << cmdCount << ": " << line << "\n";
        processLine(line, st, outfile, cmdCount);
    }
    
    infile.close();
    outfile.close();
    return 0;
}