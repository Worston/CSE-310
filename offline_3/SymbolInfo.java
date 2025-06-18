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
    private boolean isDefined;     

    public SymbolInfo(String name, String type) {
        this.name = name;
        this.type = type;
        this.isArray = false;
        this.isFunction = false;
        this.parameters = null;
        this.next = null;
        this.isDefined = false;
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

    // Constructor for functions
    public SymbolInfo(String name, String dataType, List<SymbolInfo> parameters, boolean isDefined) {
        this(name, "ID"); 
        this.isFunction = true;
        this.dataType = dataType;
        this.parameters = (parameters != null) ? new ArrayList<>(parameters) : null;
        this.isDefined = isDefined;
    }

    public String getName() { return name; }
    public String getType() { return type; }
    public String getDataType() { return dataType; }
    public boolean isArray() { return isArray; }
    public boolean isFunction() { return isFunction; }
    public List<SymbolInfo> getParameters() { return parameters; }
    public SymbolInfo getNext() { return next; }
    public int getArraySize() { return arraySize; }
    public boolean isDefined() { return isDefined; }

    public void setName(String name) { this.name = name; }
    public void setType(String type) { this.type = type; }
    public void setDataType(String dataType) { this.dataType = dataType; }
    public void setArray(boolean isArray) { this.isArray = isArray; }
    public void setFunction(boolean isFunction) { this.isFunction = isFunction; }
    public void setParameters(List<SymbolInfo> parameters) { this.parameters = parameters; }
    public void setNext(SymbolInfo next) { this.next = next; }
    public void setArraySize(int arraySize) { this.arraySize = arraySize; }
    public void setDefined(boolean isDefined) { this.isDefined = isDefined; }

    @Override
    public String toString() {
        return "< " + name + " : " + type + " >";
    }

    // Method to get function signature for semantic checking
    public String getFunctionSignature() {
        if (!isFunction) return null;

        StringBuilder sig = new StringBuilder();
        sig.append(dataType != null ? dataType : type).append("(");
        if (parameters != null) {
            for (int i = 0; i < parameters.size(); i++) {
                SymbolInfo param = parameters.get(i);
                sig.append(param.getDataType() != null ? param.getDataType() : param.getType());
                if (param.isArray()) sig.append("[]");
                if (i < parameters.size() - 1) sig.append(",");
            }
        }
        sig.append(")");
        return sig.toString();
    }

    // Method to check parameter compatibility
    public boolean isParameterCompatible(List<SymbolInfo> argList) {
        if (!isFunction) return false;

        if (parameters == null && (argList == null || argList.isEmpty())) return true;
        if (parameters == null || argList == null) return false;
        if (parameters.size() != argList.size()) return false;

        for (int i = 0; i < parameters.size(); i++) {
            SymbolInfo param = parameters.get(i);
            SymbolInfo arg = argList.get(i);

            String paramType = param.getDataType() != null ? param.getDataType() : param.getType();
            String argType = arg.getDataType() != null ? arg.getDataType() : arg.getType();
            
            if (!paramType.equals(argType)) return false;
            if (param.isArray() != arg.isArray()) return false;
        }
        return true;
    }
    
    // Check if this function declaration matches another (for declaration vs definition checking)
    public boolean matchesFunctionSignature(SymbolInfo other) {
        if (!isFunction || !other.isFunction) return false;
        
        //return types
        String thisReturn = dataType != null ? dataType : type;
        String otherReturn = other.dataType != null ? other.dataType : other.type;
        if (!thisReturn.equals(otherReturn)) return false;
        
        //parameter count
        int thisParamCount = parameters != null ? parameters.size() : 0;
        int otherParamCount = other.parameters != null ? other.parameters.size() : 0;
        if (thisParamCount != otherParamCount) return false;
        
        //parameter types
        if (parameters != null && other.parameters != null) {
            for (int i = 0; i < parameters.size(); i++) {
                SymbolInfo thisParam = parameters.get(i);
                SymbolInfo otherParam = other.parameters.get(i);
                
                String thisParamType = thisParam.getDataType() != null ? 
                    thisParam.getDataType() : thisParam.getType();
                String otherParamType = otherParam.getDataType() != null ? 
                    otherParam.getDataType() : otherParam.getType();
                
                if (!thisParamType.equals(otherParamType)) return false;
                if (thisParam.isArray() != otherParam.isArray()) return false;
            }
        }
        
        return true;
    }

    //to copy symbol info
    public SymbolInfo copy() {
        SymbolInfo copy = new SymbolInfo(this.name, this.type);
        copy.dataType = this.dataType;
        copy.isArray = this.isArray;
        copy.isFunction = this.isFunction;
        copy.arraySize = this.arraySize;
        copy.isDefined = this.isDefined;
        copy.parameters = this.parameters != null ? new ArrayList<>(this.parameters) : null;
        return copy;
    }
}
