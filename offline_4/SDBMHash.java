public class SDBMHash implements HashFunction{
    @Override
    public int hash(String str, int numBuckets) {
        if (str == null || str.isEmpty()) {
            return 0;
        }
        // int hash = 0;
        // for (char c : str.toCharArray()) {
        //     hash = c + (hash << 6) + (hash << 16) - hash;
        // }
        // return Math.abs(hash) % numBuckets;
        long hash = 0;
        for (char c : str.toCharArray()) {
            hash = (c + (hash << 6) + (hash << 16) - hash);
            hash &= 0xFFFFFFFFL; // simulate 32-bit unsigned overflow
        }
        return (int)(hash % numBuckets);
    }

    
    // Static instance for easy access
    public static final SDBMHash INSTANCE = new SDBMHash();
}
