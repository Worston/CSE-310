import java.io.PrintWriter;
import java.util.List;
import java.util.ArrayList;

public class ScopeTable {
    private SymbolInfo[] buckets;
    private int numBuckets;
    private ScopeTable parentScope;
    private String id;
    private int childCount;
    private static PrintWriter outputStream = null;
    private static PrintWriter errorStream = null;
    private HashFunction hashFunction;

    public ScopeTable(int numBuckets, ScopeTable parent) {
        this.numBuckets = numBuckets;
        this.parentScope = parent;
        this.childCount = 0;
        this.hashFunction = SDBMHash.INSTANCE; 
        
        if (parent == null) {
            this.id = "1";
        } else {
            int childNumber = parent.childCount + 1;
            this.id = parent.id + "." + childNumber;
            parent.childCount = childNumber;
        }
        
        buckets = new SymbolInfo[numBuckets];
    }

    public static void setOutputStream(PrintWriter os) {
        outputStream = os;
    }
    
    public static void setErrorStream(PrintWriter es) {
        errorStream = es;
    }

    public String getId() { return id; }
    public ScopeTable getParent() { return parentScope; }

    private int getHashIndex(String str) {
        return hashFunction.hash(str, numBuckets);
    }

    public boolean insert(SymbolInfo symbol) {
        String name = symbol.getName();
        int index = getHashIndex(name);
        SymbolInfo current = buckets[index];
        SymbolInfo prev = null;

        while (current != null) {
            if (current.getName().equals(name)) {
                // if (outputStream != null) {
                //     outputStream.printf(
                //         "\t'%s' already exists in the current scope%n", name
                //     );
                // }
                return false;
            }
            prev = current;
            current = current.getNext();
        }

        if (prev == null) {
            buckets[index] = symbol;
        } else {
            prev.setNext(symbol);
        }
        symbol.setNext(null);
        return true;
    }

    public SymbolInfo lookup(String name) {
        int index = getHashIndex(name);
        SymbolInfo current = buckets[index];

        while (current != null) {
            if (current.getName().equals(name)) {
                return current;
            }
            current = current.getNext();
        }
        return null;
    }

    public boolean remove(String name) {
        int index = getHashIndex(name);
        SymbolInfo current = buckets[index];
        SymbolInfo prev = null;

        while (current != null) {
            if (current.getName().equals(name)) {
                if (prev == null) {
                    buckets[index] = current.getNext();
                } else {
                    prev.setNext(current.getNext());
                }
                return true;
            }
            prev = current;
            current = current.getNext();
        }
        return false;
    }

    public void print(String indent) {
        if (outputStream == null) return;
        
        outputStream.println(indent + "ScopeTable # " + id);
        for (int i = 0; i < numBuckets; i++) {
            SymbolInfo current = buckets[i];
            if (current == null) continue;
            
            outputStream.print(indent + i + " --> ");
            while (current != null) {
                outputStream.print(current.toString());
                current = current.getNext();
                //if (current != null) outputStream.print(" ");
            }
            outputStream.println("");
        }
    }
    
    // Method to get all symbols in this scope (for debugging/analysis)
    public List<SymbolInfo> getAllSymbols() {
        List<SymbolInfo> symbols = new ArrayList<>();
        for (int i = 0; i < numBuckets; i++) {
            SymbolInfo current = buckets[i];
            while (current != null) {
                symbols.add(current);
                current = current.getNext();
            }
        }
        return symbols;
    }
    
    public int getSymbolCount() {
        int count = 0;
        for (int i = 0; i < numBuckets; i++) {
            SymbolInfo current = buckets[i];
            while (current != null) {
                count++;
                current = current.getNext();
            }
        }
        return count;
    }
}