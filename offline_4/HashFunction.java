@FunctionalInterface
public interface HashFunction {
    int hash(String str, int numBuckets);
}
