#ifndef SCOPETABLE_H
#define SCOPETABLE_H

#include <iostream>
#include "SymbolInfo.hpp"
#include "Hashfunctions.hpp"

class ScopeTable {
    SymbolInfo** buckets;
    int num_buckets;
    ScopeTable* parent_scope;
    std::string id;
    int childCount;
    double collisions;
    static unsigned int (*hashfunc)(const char*);
    static std::ostream* os;

public:
    ScopeTable(int n, ScopeTable* parent) : 
        num_buckets(n), parent_scope(parent), childCount(0), collisions(0) {
        if (parent == nullptr) {
            id = "1";
        } else {
            int childNumber = parent->childCount + 1;
            id = parent->id + "." + std::to_string(childNumber);
            parent->childCount = childNumber;
        }
        buckets = new SymbolInfo*[num_buckets]();
        if (os != nullptr) {
            os->flush();
        }
    }

    ~ScopeTable() {
        for (size_t i = 0; i < num_buckets; i++) {
            SymbolInfo* currentBucket = buckets[i];
            while (currentBucket != nullptr) {
                SymbolInfo* next = currentBucket->getNext();
                delete currentBucket;
                currentBucket = next;
            }
        }
        delete[] buckets;
        if (os != nullptr) {
            os->flush();
        }
    }

    std::string getId() { return id; }
    ScopeTable* getParent() { return parent_scope; }

    static void setHashFunction(unsigned int (*func)(const char*)) {
        hashfunc = func;
    }

    static void setOutputStream(std::ostream* outputStream) {
        os = outputStream;
    }

    bool insert(const std::string& name, const std::string& type) {
        unsigned int index = hashfunc(name.c_str()) % num_buckets;
        SymbolInfo* current = buckets[index];
        SymbolInfo* prev = nullptr;
        int position = 1;

        if (current != nullptr) {
            collisions++;
        }

        while (current != nullptr) {
            if (current->getName() == name) {
                if (os != nullptr) {
                    *os << "< "<<name << " : " << current->getType() 
                        << " > already exists in ScopeTable# " << id 
                        << " at position " << (index + 1) << ", " << position << "\n\n";
                }
                return false; // Symbol already exists
            }
            prev = current;
            current = current->getNext();
            position++;
        }

        SymbolInfo* newSymbol = new SymbolInfo(name, type);
        if (prev == nullptr)
            buckets[index] = newSymbol;
        else
            prev->setNext(newSymbol);

        return true;
    }

    SymbolInfo* lookup(const std::string& name) {
        unsigned int index = hashfunc(name.c_str()) % num_buckets;
        SymbolInfo* current = buckets[index];
        int position = 1;

        while (current != nullptr) {
            if (current->getName() == name) {
                return current;
            }
            current = current->getNext();
            position++;
        }
        return nullptr;
    }

    bool remove(const std::string& name) {
        unsigned int index = hashfunc(name.c_str()) % num_buckets;
        SymbolInfo* current = buckets[index];
        SymbolInfo* prev = nullptr;
        int position = 1;

        while (current != nullptr) {
            if (current->getName() == name) {
                if (prev == nullptr)
                    buckets[index] = current->getNext();
                else
                    prev->setNext(current->getNext());
                delete current;
                return true;
            }
            prev = current;
            current = current->getNext();
            position++;
        }
        return false;
    }

    void print(const std::string& indent = "") {
        if (os != nullptr) {
            *os << indent << "ScopeTable# " << id << "\n";
            for (size_t i = 0; i < num_buckets; i++) {
                SymbolInfo* current = buckets[i];
                if (current == nullptr) continue;
               
                *os << indent << (i) << " --> ";
                while (current != nullptr) {
                    std::string name = current->getName();
                    if (current->getType() == "CONST_CHAR"){
                        name = "'" + name + "'";
                        // char char_value = name.empty() ? '\0' : name[0];
                        // name = "'" + escape_char_display(char_value) + "'";
                    }
                    *os << "< " << name << " : " << current->getType() << " > ";
                    current = current->getNext();
                }
                *os << "\n";
            }
        }
    }

    double getCollisionsRato() {
        return collisions / (num_buckets * 1.0);
    }
};

unsigned int (*ScopeTable::hashfunc)(const char*) = sdbmHash;
std::ostream* ScopeTable::os = nullptr;

#endif