#include <bits/stdc++.h>
#include "ScopeTable.hpp"
#include "Hashfunctions.hpp"
using namespace std;

int main() {
    
    ScopeTable st(7, nullptr);

    // Test 1: Insert "foo" and "i"
    std::cout << "Test 1: Insert 'foo' and 'i'\n";
    bool inserted1 = st.insert("foo", "FUNCTION");
    std::cout << "Inserted 'foo': " << (inserted1 ? "Success" : "Fail") << std::endl;
    bool inserted2 = st.insert("i", "VAR");
    std::cout << "Inserted 'i': " << (inserted2 ? "Success" : "Fail") << std::endl;

    // Test 2: Lookup "i"
    std::cout << "\nTest 2: Lookup 'i'\n";
    SymbolInfo* si = st.lookup("i");
    std::cout << "Found 'i': " << (si ? "Yes" : "No") << std::endl;

    // Test 3: Delete "i"
    std::cout << "\nTest 3: Delete 'i'\n";
    bool deleted = st.remove("i");
    std::cout << "Deleted 'i': " << (deleted ? "Success" : "Fail") << std::endl;
    si = st.lookup("i");
    std::cout << "Found 'i' after deletion: " << (si ? "Yes" : "No") << std::endl;

    // Test 4: Print the scope table
    std::cout << "\nTest 4: Print Scope Table\n";
    st.print(std::cout);

    return 0;
}


/*
will find handy later when I would change hashfunc from main

#include "ScopeTable.hpp"
#include "hashfunctions.hpp"

int main() {
    // Create scope table with default hash function
    ScopeTable st(7, nullptr);
    
    // Change to another hash function
    ScopeTable::setHashFunction(anotherHashFunction);
    
    // Use the scope table
    st.insert("variable", "int");
    
    return 0;
}
*/