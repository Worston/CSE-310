import java.util.ArrayList;
import java.util.List;

public class SymbolInfo {
    private String name;
    private String type;            
    private SymbolInfo next;        
    private String dataType;       
    private boolean isArray;
    private int arraySize;         
    private boolean isFunction;
    private List<SymbolInfo> parameters;  
    private int offset;

    public SymbolInfo(String name, String type) {
        this.name = name;
        this.type = type;
        this.isArray = false;
        this.isFunction = false;
        this.parameters = null;
        this.next = null;
        this.arraySize = -1;
        this.dataType = null;
    }

    public SymbolInfo(String name, String type, boolean isArray) {
        this(name, type);
        this.isArray = isArray;
    }

    public SymbolInfo(String name, String type, int arraySize) {
        this(name, type);
        this.isArray = true;
        this.arraySize = arraySize;
    }

    public SymbolInfo(String name, String dataType, List<SymbolInfo> parameters) {
        this(name, "ID"); 
        this.isFunction = true;
        this.dataType = dataType;
        this.parameters = (parameters != null) ? new ArrayList<>(parameters) : null;
    }

    public String getName() { return name; }
    public String getType() { return type; }
    public String getDataType() { return dataType; }
    public boolean isArray() { return isArray; }
    public boolean isFunction() { return isFunction; }
    public List<SymbolInfo> getParameters() { return parameters; }
    public SymbolInfo getNext() { return next; }
    public int getArraySize() { return arraySize; }
    public int getOffset() { return offset; }

    public void setName(String name) { this.name = name; }
    public void setType(String type) { this.type = type; }
    public void setDataType(String dataType) { this.dataType = dataType; }
    public void setArray(boolean isArray) { this.isArray = isArray; }
    public void setFunction(boolean isFunction) { this.isFunction = isFunction; }
    public void setParameters(List<SymbolInfo> parameters) { this.parameters = parameters; }
    public void setNext(SymbolInfo next) { this.next = next; }
    public void setArraySize(int arraySize) { this.arraySize = arraySize; }
    public void setOffset(int offset) { this.offset = offset; }

    public boolean isParamsMatching(List<SymbolInfo> argList) {
        if (parameters == null && (argList == null || argList.isEmpty())) return true;
        if (parameters == null || argList == null) return false;
        return parameters.size() == argList.size();
    }

    @Override
    public String toString() {
        return "< " + name + " : " + type + " Offset:  " + offset +" >";
    }
}
