#include <bits/stdc++.h>
#include "SymbolTable.hpp"
#include "Hashfunctions.hpp"

using namespace std;

#define MAX_ARGS 100
#define MAX_FIELDS 50

// helpers
string trim(const string& str) {
    int first_letter = str.find_first_not_of(" \t");
    if (first_letter == string::npos) {
        return "";
    }
    int last_letter = str.find_last_not_of(" \t");
    return str.substr(first_letter, (last_letter - first_letter + 1));
}

string formatType(const string& baseType, istringstream& ss) {
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

// Function prototypes
void generateTestInputFile(const string& filename, int numBuckets, int numSymbols);
void testHashFunction(const string& name, unsigned long (*hashFunc)(const std::string&, int), 
                     const string& inputFile, ofstream& reportFile);
void runComparisonTest(const string& inputFile, const string& outputFilename);

int main(int argc, char* argv[]) {
    if (argc != 4) {
        cerr << "Usage: " << argv[0] << " <num_buckets> <num_symbols> <output_file>\n";
        cerr << "Example: " << argv[0] << " 100 500 report.txt\n";
        return 1;
    }

    int numBuckets = stoi(argv[1]);
    int numSymbols = stoi(argv[2]);
    string outputFilename = argv[3];
    string inputFile = "hash_test_input.txt";

    // Step 1: Generate test input file
    generateTestInputFile(inputFile, numBuckets, numSymbols);
    cout << "Generated test input file: " << inputFile << endl;

    // Step 2: Run comparison tests and generate report
    runComparisonTest(inputFile, outputFilename);

    cout << "Report generated successfully in " << outputFilename << endl;
    return 0;
}

void generateTestInputFile(const string& filename, int numBuckets, int numSymbols) {
    ofstream outFile(filename);
    if (!outFile) {
        cerr << "Error creating test input file: " << filename << endl;
        return;
    }

    // Write number of buckets as first line
    outFile << numBuckets << "\n";

    // Random number generator
    random_device rd;
    mt19937 gen(rd());
    uniform_int_distribution<> typeDist(0, 3);

    // Generate various types of symbols
    for (int i = 0; i < numSymbols; ++i) {
        string symbol;
        string type;
        
        // Generate different types of symbols
        int symbolType = typeDist(gen);
        switch (symbolType) {
            case 0: // Simple variable
                symbol = "var" + to_string(i);
                type = "INT";
                break;
            case 1: // Function
                symbol = "func" + to_string(i);
                type = "FUNCTION INT FLOAT CHAR";
                break;
            case 2: // Struct
                symbol = "struct" + to_string(i);
                type = "STRUCT INT mem1 FLOAT mem2";
                break;
            case 3: // Array
                symbol = "arr" + to_string(i);
                type = "ARRAY INT 10";
                break;
        }

        // Add some scope variations
        if (i % 5 == 0) {
            outFile << "S\n"; // Enter new scope
        } else if (i % 7 == 0 && i > 10) {
            outFile << "E\n"; // Exit scope (but not global)
        }

        // Write insert command
        outFile << "I " << symbol << " " << type << "\n";

        // Occasionally add some lookups and deletes
        if (i % 10 == 0 && i > 0) {
            outFile << "L " << symbol << "\n";
        }
        if (i % 15 == 0 && i > 0) {
            outFile << "D " << symbol << "\n";
        }
    }

    // Add some print commands
    outFile << "P A\n"; // Print all
    outFile << "P C\n"; // Print current
    outFile << "Q\n";   // Quit

    outFile.close();
}

void runComparisonTest(const string& inputFile, const string& outputFilename) {
    ofstream reportFile(outputFilename);
    if (!reportFile) {
        cerr << "Error opening report file: " << outputFilename << endl;
        return;
    }

    // Header for the report
    reportFile << "Hash Function Performance Comparison Report\n";
    reportFile << "==========================================\n\n";
    reportFile << "Test Input File: " << inputFile << "\n\n";
    reportFile << "Hash Functions Tested:\n";
    reportFile << "1. SDBM Hash (Default)\n";
    reportFile << "   Source: https://www.programmingalgorithms.com/algorithm/sdbm-hash/cpp/\n";
    reportFile << "2. FNV-1a Hash\n";
    reportFile << "   Source: http://www.isthe.com/chongo/tech/comp/fnv/\n";
    reportFile << "3. Jenkins Hash\n";
    reportFile << "   Source: https://www.partow.net/programming/hashfunctions/\n";
    reportFile << "4. Murmur Hash\n";
    reportFile << "   Source: https://github.com/aappleby/smhasher\n\n";

    // Test each hash function
    reportFile << "Performance Results:\n";
    reportFile << "-------------------------------\n";
    reportFile << left << setw(15) << "Hash Function" 
               << setw(20) << "Collision Ratio"//\n" ;
               << setw(20) << "" << "\n";
    reportFile << "-------------------------------\n";

    testHashFunction("SDBM", SDBMHash, inputFile, reportFile);
    testHashFunction("FNV-1a", fnv1a_hash, inputFile, reportFile);
    testHashFunction("Jenkins", jenkins_hash, inputFile, reportFile);
    testHashFunction("Murmur", murmur_hash, inputFile, reportFile);

    reportFile.close();
}

void testHashFunction(const string& name, unsigned long (*hashFunc)(const std::string&, int), 
                     const string& inputFile, ofstream& reportFile) {
    // Create a temporary output file
    string tempOutputFile = "temp_output_" + name + ".txt";
    ofstream tempOutput(tempOutputFile);
    if (!tempOutput) {
        cerr << "Error creating temporary output file for " << name << endl;
        return;
    }

    // Set up symbol table with this hash function
    ScopeTable::setHashFunction(hashFunc);
    SymbolTable::setOutputStream(&tempOutput);
    ScopeTable::setOutputStream(&tempOutput);
    ScopeTable::setNextId();

    // Read input file
    ifstream infile(inputFile);
    if (!infile) {
        cerr << "Error opening input file: " << inputFile << endl;
        return;
    }

    // First line contains number of buckets
    string line;
    getline(infile, line);
    int numBuckets = stoi(trim(line));
    SymbolTable st(numBuckets);

    // Process commands
    int cmdCount = 0;
    while (getline(infile, line)) {
        line = trim(line);
        if (line.empty()) continue;
        cmdCount++;
        tempOutput << "Cmd " << cmdCount << ": " << line << "\n";
        
        istringstream ss(line);
        string cmd;
        ss >> cmd;

        if (cmd == "I") {
            string name, baseType;
            ss >> name >> baseType;
            string remaining;
            getline(ss, remaining);
            remaining = trim(remaining);
            
            istringstream paramStream(remaining);
            string formattedType = formatType(baseType, paramStream);
            st.insert(name, formattedType);
        }
        else if (cmd == "L") {
            string name;
            ss >> name;
            st.lookup(name);
        }
        else if (cmd == "D") {
            string name;
            ss >> name;
            st.remove(name);
        }
        else if (cmd == "P") {
            char mode;
            ss >> mode;
            if (mode == 'C') st.printCurrentScope();
            else st.printAllScope();
        }
        else if (cmd == "S") st.enterScope();
        else if (cmd == "E") st.exitScope();
        else if (cmd == "Q") break;
    }

    infile.close();
    tempOutput.close();

    // Get metrics from the symbol table
    double ratio = st.getRatio();

    // Output results
    reportFile << left << setw(15) << name 
               << setw(20) << fixed << setprecision(4) << ratio<<"\n";
               //<< setw(20) << "N/A"; // Max chain length would need to be tracked in ScopeTable
}

