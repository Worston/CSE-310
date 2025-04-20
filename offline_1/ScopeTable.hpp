#ifndef SCOPETABLE_H
#define SCOPETABLE_H

#include "SymbolInfo.hpp"
#include "Hashfunctions.hpp"
#include <iostream>

class ScopeTable{
    SymbolInfo** buckets;
    int num_buckets;
    ScopeTable* parent_scope;
    int id;
    static int nextId;
    static unsigned long (*hashfunc) (const std::string, const int);
    static std::ostream* os;
    // might need a collisions variable for collision resolution
   
   public:
    ScopeTable(int n, ScopeTable* parent): 
        num_buckets(n), parent_scope(parent){
        id = nextId++;
        buckets = new SymbolInfo*[num_buckets]();  
        // std::cout << "Scopetable ki create hoise?\n";
        if(os != nullptr) {
            *os << "\tScopeTable# " << id << " created\n";
            os -> flush();
        }
    }

    ~ScopeTable(){
        for (size_t i = 0; i < num_buckets; i++){
            SymbolInfo* currentBucket = buckets[i];
            while(currentBucket != nullptr){
                SymbolInfo* next = currentBucket -> getNext();
                delete currentBucket;
                currentBucket = next;
            } 
        }

        delete [] buckets;

        if(os != nullptr) {
            *os<< "\tScopeTable# " << id << " removed\n";
            os -> flush();
        }
    }

    int getId() { return id; }
    ScopeTable* getParent() { return parent_scope; }

    static void setHashFunction(unsigned long (*func) (const std::string, const int)){
        hashfunc = func;
    }

    static void setOutputStream(std::ostream* outputStream){
        os = outputStream;
    }

    bool insert(const std::string& name, const std::string& type){
        unsigned long index = hashfunc(name, num_buckets) % num_buckets;
        SymbolInfo* current = buckets[index];
        SymbolInfo* prev = nullptr;
        int position = 1;

        while (current != nullptr){
            if (current -> getName() == name) return false; // already exists
                
            prev = current;
            current = current -> getNext();
            position++;
            // might increment the collision here
        }
        
        SymbolInfo* newSymbol = new SymbolInfo(name, type);
        if (prev == nullptr)
            buckets[index] = newSymbol;
        else 
            prev -> setNext(newSymbol);

        // might need to delete this line afterwards    
        if(os != nullptr){
            *os << "Inserted in ScopeTable# " << id << " at position "<<(index+1)<<", "<<position<<"\n"; 
            os -> flush();
        } 
        return true;
    }

    SymbolInfo* lookup(const std::string& name){
        unsigned long index = hashfunc(name, num_buckets) % num_buckets;
        SymbolInfo* current = buckets[index];
        int position = 1;

        while (current != nullptr){
            if (current -> getName() == name){

                // might need to delete this line afterwards
                if(os != nullptr) {
                    *os <<"'"<<name<<"'"<<" found in ScopeTable# "<< id << " at position "<<(index+1)<<", "<< position<<"\n";
                    os -> flush();
                }
                return current;
            }
            current = current -> getNext();
            position++;
        }
        return nullptr;
    }

    bool remove(const std::string& name){
        unsigned long index = hashfunc(name, num_buckets) % num_buckets;
        SymbolInfo* current = buckets[index];
        SymbolInfo* prev = nullptr;
        int position = 1;

        while (current != nullptr){
            if (current -> getName() == name){
                if (prev == nullptr)
                    buckets[index] = current -> getNext();
                else
                    prev -> setNext(current -> getNext());

                delete current;

                // might need to delete this line afterwards
                if(os != nullptr) {
                    *os<<"Deleted "<<"'"<<name<<"'"<<" from ScopeTable# "<< id <<" at position "<<(index+1)<<", "<<position<<"\n";
                    os -> flush();
                }
                return true;
            }
            prev = current;
            current = current -> getNext();
            position++;
        }
        return false; //symbol not found
    }

    void print(){
        if(os != nullptr) *os << "ScopeTable# " << id << "\n";
        for (size_t i = 0; i < num_buckets; i++){
            *os << "\t" << (i+1) << " --> ";
            SymbolInfo* current = buckets[i];
            while (current != nullptr){
                if(os != nullptr)
                    *os << "<" << current->getName() << ", " << current->getType() << "> ";
                current = current->getNext();
            }
            if(os != nullptr) *os << "\n";
        }
        os->flush();
    }
};


int ScopeTable::nextId = 1;
// This will be used to set the hashfunction from symbol table 
unsigned long (*ScopeTable::hashfunc)(const std::string, const int) = SDBMHash;
std::ostream* ScopeTable::os = nullptr;

#endif