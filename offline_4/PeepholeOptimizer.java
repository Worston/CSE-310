import java.io.*;
import java.util.*;

public class PeepholeOptimizer {

    public void optimize(String inputFile, String outputFile) throws IOException {
        List<String> lines = readAssemblyCode(inputFile);
        int initialSize;
        do {
            initialSize = lines.size();
            lines = optimizeIncDec(lines);
            lines = removeRedundantMov(lines);
            lines = removeRedundantPushPop(lines);
            lines = removeRedundantOperations(lines);
            lines = optimizeLabelsAndUpdateJumps(lines);
        } while (lines.size() < initialSize);

        writeOptimizedCode(outputFile, lines);
    }

    private List<String> readAssemblyCode(String filename) throws IOException {
        List<String> lines = new ArrayList<>();
        try (BufferedReader reader = new BufferedReader(new FileReader(filename))) {
            String line;
            while ((line = reader.readLine()) != null) {
                lines.add(line);
            }
        }
        return lines;
    }

    private void writeOptimizedCode(String filename, List<String> lines) throws IOException {
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(filename))) {
            for (String line : lines) {
                writer.write(line);
                writer.newLine();
            }
        }
    }

    private List<String> removeRedundantMov(List<String> lines) {
        List<String> optimized = new ArrayList<>();
        
        for (int i = 0; i < lines.size(); i++) {
            if (i + 1 < lines.size()) {
                String current = lines.get(i).trim();
                String next = lines.get(i + 1).trim();
                
                //if both lines are MOV instructions
                if (isMoveInstruction(current) && isMoveInstruction(next)) {
                    String[] currentParts = parseMoveInstruction(current);
                    String[] nextParts = parseMoveInstruction(next);
                    
                    if (currentParts != null && nextParts != null) {
                        String dest1 = currentParts[0];
                        String src1 = currentParts[1];
                        String dest2 = nextParts[0];
                        String src2 = nextParts[1];
                        
                        //MOV A, B followed by MOV B, A
                        if (dest1.equals(src2) && src1.equals(dest2)) {
                            optimized.add(lines.get(i)); // Keeping first MOV
                            i++; // Skip second MOV
                            continue;
                        }
                    }
                }
            }
            optimized.add(lines.get(i));
        }
        return optimized;
    }

    private List<String> removeRedundantPushPop(List<String> lines) {
        List<String> optimized = new ArrayList<>();
        
        for (int i = 0; i < lines.size(); i++) {
            if (i + 1 < lines.size()) {
                String current = lines.get(i).trim();
                String next = lines.get(i + 1).trim();
                
                if (isPushInstruction(current) && isPopInstruction(next)) {
                    String pushOperand = extractOperand(current, "PUSH");
                    String popOperand = extractOperand(next, "POP");
                    
                    if (pushOperand != null && popOperand != null && pushOperand.equals(popOperand)) {
                        i++; // Skip both PUSH and POP
                        continue;
                    }
                }
            }
            optimized.add(lines.get(i));
        }
        return optimized;
    }

    private List<String> removeRedundantOperations(List<String> lines) {
        List<String> optimized = new ArrayList<>();
        
        for (String line : lines) {
            String trimmed = line.trim();
            
            // ADD/SUB with 0
            if (isArithmeticWithZero(trimmed)) {
                continue; // Skip line
            }
            optimized.add(line);
        }
        return optimized;
    }

    private List<String> optimizeLabelsAndUpdateJumps(List<String> lines) {
        Map<String, String> labelMap = new HashMap<>();
        List<String> pass1 = new ArrayList<>();

        // First pass: find consecutive labels
        for (int i = 0; i < lines.size(); i++) {
            String trimmed = lines.get(i).trim();
            
            if (isLabel(trimmed)) {
                String currentLabel = extractLabelName(trimmed);
                int j = i + 1;
                
                // consecutive labels
                while (j < lines.size() && isLabel(lines.get(j).trim())) {
                    String nextLabel = extractLabelName(lines.get(j).trim());
                    labelMap.put(nextLabel, currentLabel);
                    j++;
                }
                pass1.add(lines.get(i));
                i = j - 1;
            } else {
                pass1.add(lines.get(i));
            }
        }

        // Second pass: update jumps
        List<String> pass2 = new ArrayList<>();
        for (String line : pass1) {
            String trimmed = line.trim();
            
            if (isJumpInstruction(trimmed)) {
                String[] jumpParts = parseJumpInstruction(trimmed);
                if (jumpParts != null) {
                    String jumpType = jumpParts[0];
                    String label = jumpParts[1];
                    
                    // Follow label chain
                    while (labelMap.containsKey(label)) {
                        label = labelMap.get(label);
                    }
                    pass2.add("\t" + jumpType + " " + label);
                } else {
                    pass2.add(line);
                }
            } else {
                pass2.add(line);
            }
        }
        return pass2;
    }

    private List<String> optimizeIncDec(List<String> lines) {
        List<String> optimized = new ArrayList<>();
        
        for (int i = 0; i < lines.size(); i++) {
            if (i + 4 < lines.size()) {
                String line1 = lines.get(i).trim();
                String line2 = lines.get(i + 1).trim();
                String line3 = lines.get(i + 2).trim();
                String line4 = lines.get(i + 3).trim();
                String line5 = lines.get(i + 4).trim();
                
                // 5-instruction pattern
                if (isMovFromMemoryToAX(line1) && 
                    isPushAX(line2) && 
                    isIncDecAX(line3) && 
                    isMovFromAXToMemory(line4) && 
                    isPopAX(line5)) {
                    
                    String memOperand1 = extractMemoryOperand(line1);
                    String memOperand2 = extractMemoryOperand(line4);
                    String operation = extractIncDecOperation(line3);
                    
                    if (memOperand1 != null && memOperand2 != null && 
                        memOperand1.equals(memOperand2)) {
                        
                        optimized.add(lines.get(i)); // first MOV
                        optimized.add("\t" + operation + " WORD PTR " + memOperand1);
                        
                        i += 4; // Skip next 4 lines
                        continue;
                    }
                }
            }
            optimized.add(lines.get(i));
        }
        return optimized;
    }

    private boolean isMoveInstruction(String line) {
        return line.startsWith("MOV ");
    }

    private String[] parseMoveInstruction(String line) {
        if (!line.startsWith("MOV ")) return null;
        
        String operands = line.substring(4).trim();
        int commaIndex = operands.indexOf(',');
        if (commaIndex == -1) return null;
        
        String dest = operands.substring(0, commaIndex).trim();
        String src = operands.substring(commaIndex + 1).trim();
        
        // Remove comments
        int commentIndex = src.indexOf(';');
        if (commentIndex != -1) {
            src = src.substring(0, commentIndex).trim();
        }
        
        return new String[]{dest, src};
    }

    private boolean isPushInstruction(String line) {
        return line.startsWith("PUSH ");
    }

    private boolean isPopInstruction(String line) {
        return line.startsWith("POP ");
    }

    private String extractOperand(String line, String instruction) {
        if (!line.startsWith(instruction + " ")) return null;
        
        String operand = line.substring(instruction.length() + 1).trim();
        int commentIndex = operand.indexOf(';');
        if (commentIndex != -1) {
            operand = operand.substring(0, commentIndex).trim();
        }
        return operand;
    }

    private boolean isArithmeticWithZero(String line) {
        if (line.startsWith("ADD ") || line.startsWith("SUB ")) {
            int commaIndex = line.indexOf(',');
            if (commaIndex != -1) {
                String secondOperand = line.substring(commaIndex + 1).trim();
                int commentIndex = secondOperand.indexOf(';');
                if (commentIndex != -1) {
                    secondOperand = secondOperand.substring(0, commentIndex).trim();
                }
                return secondOperand.equals("0");
            }
        }
        return false;
    }

    private boolean isLabel(String line) {
        return line.startsWith("L") && line.endsWith(":") && 
               isNumeric(line.substring(1, line.length() - 1));
    }

    private String extractLabelName(String line) {
        if (line.endsWith(":")) {
            return line.substring(0, line.length() - 1);
        }
        return null;
    }

    private boolean isJumpInstruction(String line) {
        return line.startsWith("JMP ") || line.startsWith("JE ") || 
               line.startsWith("JNE ") || line.startsWith("JG ") || 
               line.startsWith("JL ") || line.startsWith("JGE ") || 
               line.startsWith("JLE ") || line.startsWith("CALL ");
    }

    private String[] parseJumpInstruction(String line) {
        String[] parts = line.split(" ", 2);
        if (parts.length == 2) {
            return new String[]{parts[0], parts[1].trim()};
        }
        return null;
    }

    private boolean isMovFromMemoryToAX(String line) {
        return line.startsWith("MOV AX, ") && 
               (line.contains("[") || line.contains("SS:"));
    }

    private boolean isPushAX(String line) {
        return line.equals("PUSH AX");
    }

    private boolean isIncDecAX(String line) {
        return line.equals("INC AX") || line.equals("DEC AX");
    }

    private boolean isMovFromAXToMemory(String line) {
        return line.startsWith("MOV ") && line.endsWith(", AX") &&
               (line.contains("[") || line.contains("SS:"));
    }

    private boolean isPopAX(String line) {
        return line.equals("POP AX");
    }

    private String extractMemoryOperand(String line) {
        if (line.startsWith("MOV AX, ")) {
            return line.substring(8).trim();
        } else if (line.startsWith("MOV ") && line.endsWith(", AX")) {
            return line.substring(4, line.length() - 4).trim();
        }
        return null;
    }

    private String extractIncDecOperation(String line) {
        if (line.startsWith("INC ")) return "INC";
        if (line.startsWith("DEC ")) return "DEC";
        return null;
    }

    private boolean isNumeric(String str) {
        try {
            Integer.parseInt(str);
            return true;
        } catch (NumberFormatException e) {
            return false;
        }
    }

    public static void performOptimization(String inputFile, String outputFile) {
        PeepholeOptimizer optimizer = new PeepholeOptimizer();
        try {
            optimizer.optimize(inputFile, outputFile);
        } catch (IOException e) {
            System.err.println("Error during optimization: " + e.getMessage());
        }
    }
}
