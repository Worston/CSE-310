import java.io.*;
import java.util.*;
import java.util.regex.*;

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
        } while (lines.size() < initialSize); // Loop until no more optimizations are found

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

                Pattern movPattern = Pattern.compile("^MOV\\s+([^,]+),\\s*([^;]+)");
                Matcher m1 = movPattern.matcher(current);
                Matcher m2 = movPattern.matcher(next);

                if (m1.find() && m2.find()) {
                    String dest1 = m1.group(1).trim();
                    String src1 = m1.group(2).trim();
                    String dest2 = m2.group(1).trim();
                    String src2 = m2.group(2).trim();

                    // Check for MOV reg, mem -> MOV mem, reg
                    if (dest1.equals(src2) && src1.equals(dest2)) {
                        optimized.add(lines.get(i)); // Keep the first MOV
                        i++; // Skip the redundant second MOV
                        continue;
                    }
                }
            }
            optimized.add(lines.get(i));
        }
        return optimized;
    }

    // Correct: PUSH reg -> POP reg
    private List<String> removeRedundantPushPop(List<String> lines) {
        List<String> optimized = new ArrayList<>();
        for (int i = 0; i < lines.size(); i++) {
            if (i + 1 < lines.size()) {
                String current = lines.get(i).trim();
                String next = lines.get(i + 1).trim();

                Pattern pushPattern = Pattern.compile("^PUSH\\s+([^;]+)");
                Pattern popPattern = Pattern.compile("^POP\\s+([^;]+)");
                Matcher m1 = pushPattern.matcher(current);
                Matcher m2 = popPattern.matcher(next);

                if (m1.find() && m2.find()) {
                    if (m1.group(1).trim().equals(m2.group(1).trim())) {
                        i++; // Skip both PUSH and POP
                        continue;
                    }
                }
            }
            optimized.add(lines.get(i));
        }
        return optimized;
    }

    //ADD/SUB with 0
    private List<String> removeRedundantOperations(List<String> lines) {
        List<String> optimized = new ArrayList<>();
        for (String line : lines) {
            String trimmed = line.trim();
            if (trimmed.matches("^(ADD|SUB)\\s+[^,]+,\\s*0(\\s*;.*)?$")) {
                continue; 
            }
            optimized.add(line);
        }
        return optimized;
    }

    private List<String> optimizeLabelsAndUpdateJumps(List<String> lines) {
        Map<String, String> labelMap = new HashMap<>();
        List<String> pass1 = new ArrayList<>();

        // First pass: find consecutive labels and build the map
        for (int i = 0; i < lines.size(); i++) {
            String trimmed = lines.get(i).trim();
            if (trimmed.matches("^L\\d+:$")) {
                String currentLabel = trimmed.substring(0, trimmed.length() - 1);
                int j = i + 1;
                while (j < lines.size() && lines.get(j).trim().matches("^L\\d+:$")) {
                    String nextLabel = lines.get(j).trim();
                    nextLabel = nextLabel.substring(0, nextLabel.length() - 1);
                    labelMap.put(nextLabel, currentLabel);
                    j++;
                }
                pass1.add(lines.get(i));
                i = j - 1; // Skip the redundant labels 
            } else {
                pass1.add(lines.get(i));
            }
        }

        // Second pass: update all jumps using the map
        List<String> pass2 = new ArrayList<>();
        Pattern jumpPattern = Pattern.compile("^(JMP|JE|JNE|JG|JL|JGE|JLE|CALL)\\s+(L\\d+)");
        for (String line : pass1) {
            Matcher m = jumpPattern.matcher(line.trim());
            if (m.find()) {
                String jumpType = m.group(1);
                String label = m.group(2);
                // Follow the chain of labels until we find the final one
                while (labelMap.containsKey(label)) {
                    label = labelMap.get(label);
                }
                pass2.add("\t" + jumpType + " " + label);
            } else {
                pass2.add(line);
            }
        }
        return pass2;
    }

    private List<String> optimizeIncDec(List<String> lines) {
        List<String> optimized = new ArrayList<>();
        Pattern movPattern = Pattern.compile("^MOV\\s+AX,\\s*([^;]+)");
        Pattern pushPattern = Pattern.compile("^PUSH\\s+AX");
        Pattern incDecPattern = Pattern.compile("^(INC|DEC)\\s+AX");
        Pattern movBackPattern = Pattern.compile("^MOV\\s+([^,]+),\\s*AX");
        Pattern popPattern = Pattern.compile("^POP\\s+AX");

        for (int i = 0; i < lines.size(); i++) {
            //enough lines for the 5-instruction pattern
            if (i + 4 < lines.size()) {
                Matcher m1 = movPattern.matcher(lines.get(i).trim());
                Matcher m2 = pushPattern.matcher(lines.get(i + 1).trim());
                Matcher m3 = incDecPattern.matcher(lines.get(i + 2).trim());
                Matcher m4 = movBackPattern.matcher(lines.get(i + 3).trim());
                Matcher m5 = popPattern.matcher(lines.get(i + 4).trim());

                //all 5 patterns match in sequence
                if (m1.find() && m2.find() && m3.find() && m4.find() && m5.find()) {
                    String memOperand1 = m1.group(1).trim();
                    String memOperand2 = m4.group(1).trim();
                    String operation = m3.group(1); // "INC" or "DEC"

                    // Check if the memory location is the same in MOV and MOV back
                    if (memOperand1.equals(memOperand2)) {
                        optimized.add(lines.get(i)); // Keep the first MOV: MOV AX, [mem]
                        optimized.add("\t" + operation + " WORD PTR " + memOperand1); // Add INC/DEC [mem]

                        i += 4; // Skip the next 4 lines which we have now replaced
                        continue;
                    }
                }
            }
            //no pattern was matched
            optimized.add(lines.get(i));
        }
        return optimized;
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
