import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

public class SymbolTable {
    private ScopeTable currentScope;
    private int numBuckets;
    private static PrintWriter outputStream = null;
    private static PrintWriter errorStream = null;
    private List<SymbolInfo> pendingParameters = new ArrayList<>();

    public SymbolTable(int numBuckets) {
        this.numBuckets = numBuckets;
        this.currentScope = new ScopeTable(numBuckets, null);
    }

    public static void setOutputStream(PrintWriter os) {
        outputStream = os;
        ScopeTable.setOutputStream(os); 
    }
    
    public static void setErrorStream(PrintWriter es) {
        errorStream = es;
        ScopeTable.setErrorStream(es); 
    }

    public void enterScope() {
        currentScope = new ScopeTable(numBuckets, currentScope);
    }

    public void exitScope() {
        if (currentScope.getParent() == null) {
            if (outputStream != null) {
                outputStream.println("\tCannot exit the global scope");
            }
            return;
        }
        
        // Print the symbol table before removing it
        //currentScope.print("");
        printAllScopes();
        currentScope = currentScope.getParent();
    }

    public boolean insert(SymbolInfo symbol) {
        return currentScope.insert(symbol);
    }

    public boolean remove(String name) {
        return currentScope.remove(name);
    }

    public SymbolInfo lookup(String name) {
        ScopeTable curr = currentScope;
        while (curr != null) {
            SymbolInfo found = curr.lookup(name);
            if (found != null) {
                return found;
            }
            curr = curr.getParent();
        }
        return null;
    }

    public SymbolInfo lookupCurrentScope(String name) {
        return currentScope.lookup(name);
    }

    public void printCurrentScope() {
        currentScope.print("");
    }

    public void printAllScopes() {
        ScopeTable curr = currentScope;
        while (curr != null) {
            curr.print("");
            curr = curr.getParent();
        }
        outputStream.println("");
    }
    
    public String getCurrentScopeId() {
        return currentScope.getId();
    }
    
    public ScopeTable getCurrentScope() {
        return currentScope;
    }

    public void addPendingParameter(SymbolInfo param, int lineNumber) {
        for (SymbolInfo params : pendingParameters) {
            if (params.getName().equals(param.getName())) {
                String errorMsg =  "Error at line " + lineNumber + ": Multiple declaration of " + param.getName() + " in parameter\n";
                outputStream.println(errorMsg);
                outputStream.flush();
                errorStream.println(errorMsg);
                errorStream.flush();
                Main.syntaxErrorCount++;  
            }
        }
        pendingParameters.add(param);
    }

    public void insertPendingParameters() {
        for (SymbolInfo param : pendingParameters) {
            insert(param);
        }
        pendingParameters.clear();
    }

    public void clearPendingParameters() {
        pendingParameters.clear();
    }

    public List<SymbolInfo> getPendingParameters() {
        return new ArrayList<>(pendingParameters);
    }

    public boolean insertWithErrorReporting(SymbolInfo symbol, int lineNumber) {
        if (insert(symbol)) {
            return true;
        } else {
            String errorMsg = "Error at line " + lineNumber + ": Multiple declaration of " + symbol.getName()+"\n";
            outputStream.println(errorMsg);
            outputStream.flush();
            errorStream.println(errorMsg);
            errorStream.flush();
            return false;
        }
    }

    public boolean insertFunction(String name, String returnType, List<SymbolInfo> parameters, int lineNumber) {
        SymbolInfo function = new SymbolInfo(name, returnType, parameters, false);
        SymbolInfo ifContainsFunc = lookup(name);

        if (ifContainsFunc != null) {
            if (ifContainsFunc.isFunction() && !ifContainsFunc.isDefined()) {
                //checking if return type matches
                if (!ifContainsFunc.getDataType().equals(returnType)) {
                    String errorMsg = "Error at line " + lineNumber + ": Return type mismatch of " + name + "\n" ;
                    outputStream.println(errorMsg);
                    outputStream.flush();
                    errorStream.println(errorMsg);
                    errorStream.flush();
                    Main.syntaxErrorCount++;
                }
                //checking if parameter count matches
                if (!ifContainsFunc.isParamsMatching(parameters)) {
                    String errorMsg = "Error at line " + lineNumber + ": Total number of arguments mismatch with declaration in function " + name + "\n" ;
                    outputStream.println(errorMsg);
                    outputStream.flush();
                    errorStream.println(errorMsg);
                    errorStream.flush();
                    Main.syntaxErrorCount++;
                }
            } else {
                String errorMsg = "Error at line " + lineNumber + ": Multiple declaration of " + name + "\n" ;
                outputStream.println(errorMsg);
                outputStream.flush();
                errorStream.println(errorMsg);
                errorStream.flush();
                Main.syntaxErrorCount++;
            }
        }

        return insert(function);
    }

    public boolean insertFunction(String name, String returnType, List<SymbolInfo> parameters) {
        SymbolInfo function = new SymbolInfo(name, returnType, parameters, false);
        return insert(function);
    }

    //overloaded to test
    public boolean insertArray(String name, String dataType, int arraySize, int lineNumber) {
        SymbolInfo symbol = new SymbolInfo(name, "ID");
        symbol.setDataType(dataType);
        symbol.setArray(true);
        if (arraySize > 0) {
            symbol.setArraySize(arraySize);
        }
        return insertWithErrorReporting(symbol, lineNumber);
    }
    
    // Convenience method to insert variable symbols
    public boolean insertVariable(String name, String dataType) {
        SymbolInfo variable = new SymbolInfo(name, "ID");
        variable.setDataType(dataType);
        return insert(variable);
    }

    //overloaded to test
    public boolean insertVariable(String name, String dataType, int lineNumber) {
        SymbolInfo symbol = new SymbolInfo(name, "ID");
        symbol.setDataType(dataType);
        return insertWithErrorReporting(symbol, lineNumber);
    }
    
    // Method to check if a variable is declared before use
    public boolean isDeclared(String name) {
        return lookup(name) != null;
    }
    
    // Method to get function for semantic checking
    public SymbolInfo getFunction(String name) {
        SymbolInfo symbol = lookup(name);
        if (symbol != null && symbol.isFunction()) {
            return symbol;
        }
        return null;
    }
    
    // Method to check if symbol exists in current scope only
    public boolean existsInCurrentScope(String name) {
        return lookupCurrentScope(name) != null;
    }
}