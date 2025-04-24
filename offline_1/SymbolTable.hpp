#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H

#include <iostream>
#include "ScopeTable.hpp"

class SymbolTable{
    ScopeTable* currentScope;
    int num_buckets;
    static std::ostream* outputStream;

   public:
    SymbolTable(int n) : num_buckets(n){
        currentScope = new ScopeTable(n, nullptr); 
    }

    ~SymbolTable(){
        while (currentScope != nullptr){
            ScopeTable* parent = currentScope -> getParent();
            int id = currentScope -> getId();
            delete currentScope;
            currentScope = parent;
        }
    }

    static void setOutputStream(std::ostream* os) {
        outputStream = os;
    }

    // static void setHashFunction(unsigned long (*func)(const std::string&, const int)) {
    //     ScopeTable::setHashFunction(func); 
    // }

    void enterScope(){
        ScopeTable* newScope = new ScopeTable(num_buckets, currentScope);
        currentScope = newScope;
    }

    void exitScope(){
        ScopeTable* parent = currentScope -> getParent();

        if (parent == nullptr){
            // need to sort out how we can print this to the file
            if(outputStream != nullptr) {
                *outputStream << "\tCannot exit the global scope\n";
                outputStream -> flush();
            }
            return;
        }
        delete currentScope;
        currentScope = parent;
    }

    bool insert(const std::string& name, const std::string& type){
        return currentScope -> insert(name, type);
    }

    bool remove(const std::string& name){
        return currentScope -> remove(name);
    }

    SymbolInfo* lookup(const std::string& name){
        ScopeTable* curr = currentScope;

        while (curr != nullptr){
            SymbolInfo* found = curr -> lookup(name);
            if (found != nullptr)
                return found;
            curr = curr -> getParent();    
        }
        return nullptr;
    }

    void printCurrentScope(){
        currentScope->print("\t");
    }
    
    void printAllScope(){
        ScopeTable* curr = currentScope;
        std::string indent = "\t";
        while (curr != nullptr) {
            curr->print(indent);
            indent += "\t";
            curr = curr->getParent();
        }
    }

    double getRatio(){
        int count = 0;

        ScopeTable* parent = currentScope -> getParent();
        if (parent == nullptr){
            return currentScope -> getCollisionsRato();
        }

        ScopeTable* curr = currentScope;
        double ratio = 0;

        while (curr != nullptr){
            ratio += curr -> getCollisionsRato();
            curr = curr -> getParent();
            count ++;
        }
        return ratio / count;
    }
};

std::ostream* SymbolTable::outputStream = nullptr;

#endif