#include<bits/stdc++.h>
using namespace std;

int main(int argc, char const *argv[]){
    cout<<"Hello";
    return 0;
}


// #include "SymbolTable.hpp"
// #include <cassert>

// void test_basic_scope() {
//     SymbolTable st(7);
    
//     // Test 1: Insert into global scope
//     assert(st.insert("x", "VAR") == true);
//     assert(st.lookup("x") != nullptr);
    
//     // Test 2: Enter new scope and insert
//     st.enterScope();
//     assert(st.insert("y", "FUNCTION") == true);
//     assert(st.lookup("y") != nullptr);
    
//     // Test 3: Lookup in parent scope
//     assert(st.lookup("x") != nullptr); // Found in parent
    
//     // Test 4: Exit scope and verify cleanup
//     st.exitScope();
//     assert(st.lookup("y") == nullptr); // y is gone
// }

// void test_duplicate_insert() {
//     SymbolTable st(7);
//     assert(st.insert("a", "VAR") == true);
//     assert(st.insert("a", "VAR") == false); // Duplicate
// }

// void test_remove() {
//     SymbolTable st(7);
//     st.insert("x", "VAR");
//     assert(st.remove("x") == true);
//     assert(st.lookup("x") == nullptr);
//     assert(st.remove("x") == false); // Already deleted
// }

// void test_nested_scopes() {
//     SymbolTable st(7);
//     st.insert("g", "GLOBAL");
//     st.enterScope();
//     st.insert("s1", "SCOPE1");
//     st.enterScope();
//     st.insert("s2", "SCOPE2");
//     assert(st.lookup("g") != nullptr); // Global accessible
//     st.exitScope();
//     assert(st.lookup("s2") == nullptr); // s2 gone
// }

// void test_duplicate_in_same_scope() {
//     SymbolTable st(7);
//     st.insert("x", "VAR");
//     assert(st.insert("x", "FUNCTION") == false);
// }

// void test_empty_table(){
//     SymbolTable st(7);
//     assert(st.lookup("ghost") == nullptr);
// }

// void test_multiple_nested_scopes(){
//     SymbolTable st(7);
//     st.enterScope(); // Scope 2
//     st.enterScope(); // Scope 3
//     st.insert("z", "VAR");
//     st.exitScope();  // Scope 3 removed
//     assert(st.lookup("z") == nullptr); // Should fail
// }

// int main() {
//     test_basic_scope();
//     test_duplicate_insert();
//     test_remove();
//     test_nested_scopes();
//     test_duplicate_in_same_scope();
//     test_empty_table();
//     test_multiple_nested_scopes();
    
//     std::cout << "All tests passed!\n";
//     return 0;
// }