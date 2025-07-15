import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

public class SymbolTable {
    private ScopeTable currentScope;
    private int numBuckets;
    private static PrintWriter outputStream = null;
    private List<SymbolInfo> pendingParameters = new ArrayList<>();

    public SymbolTable(int numBuckets) {
        this.numBuckets = numBuckets;
        this.currentScope = new ScopeTable(numBuckets, null);
    }

    public static void setOutputStream(PrintWriter os) {
        outputStream = os;
        ScopeTable.setOutputStream(os); 
    }

    public void enterScope() {
        currentScope = new ScopeTable(numBuckets, currentScope);
    }

    public void exitScope() {
        if (currentScope.getParent() == null) {
            return;
        }
        
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

    public void addPendingParameter(SymbolInfo param) {
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

    public boolean insertFunction(String name, String returnType, List<SymbolInfo> parameters) {
        SymbolInfo function = new SymbolInfo(name, returnType, parameters);
        return insert(function);
    }

    public boolean insertArray(String name, String dataType, int arraySize) {
        SymbolInfo symbol = new SymbolInfo(name, "ID");
        symbol.setDataType(dataType);
        symbol.setArray(true);
        if (arraySize > 0) {
            symbol.setArraySize(arraySize);
        }
        return insert(symbol);
    }
    
    public boolean insertVariable(String name, String dataType) {
        SymbolInfo variable = new SymbolInfo(name, "ID");
        variable.setDataType(dataType);
        return insert(variable);
    }

    public boolean isDeclared(String name) {
        return lookup(name) != null;
    }
    
    public SymbolInfo getFunction(String name) {
        SymbolInfo symbol = lookup(name);
        if (symbol != null && symbol.isFunction()) {
            return symbol;
        }
        return null;
    }
    
    public boolean existsInCurrentScope(String name) {
        return lookupCurrentScope(name) != null;
    }
}