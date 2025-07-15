antlr4 -v 4.13.2 C2105015Lexer.g4 C2105015Parser.g4
javac -cp .:/usr/local/lib/antlr-4.13.2-complete.jar  C2105015*.java Main.java
java -cp .:/usr/local/lib/antlr-4.13.2-complete.jar Main $1
