#ifndef SYMBOLINFO_H
#define SYMBOLINFO_H

#include <string>

class SymbolInfo {
    std::string name;    
    std::string type;    
    SymbolInfo* next;    

   public:
    SymbolInfo(const std::string& name = "", const std::string& type = "")
    : name(name), type(type), next(nullptr) {}

    const std::string& getName() const { return name; }
    const std::string& getType() const { return type; }
    SymbolInfo* getNext() const { return next; }

    void setName(const std::string& newName) { name = newName; }
    void setType(const std::string& newType) { type = newType; }
    void setNext(SymbolInfo* newNext) { next = newNext; }
};

#endif


