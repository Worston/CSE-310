#ifndef HASHFUNCTIONS_H
#define HASHFUNCTIONS_H

#include <string>

// source: https://www.programmingalgorithms.com/algorithm/sdbm-hash/cpp/
unsigned long SDBMHash(const std::string& str, int num_buckets) {
	unsigned long hash = 0;
	unsigned int i = 0;
	unsigned int len = str.length();

	for (i = 0; i < len; i++){
		hash = (str[i]) + (hash << 6) + (hash << 16) - hash;
		hash = hash % num_buckets;
	}

	return hash;
}

// source: http://www.isthe.com/chongo/tech/comp/fnv/
unsigned long fnv1a_hash(const std::string& str, int num_buckets) {
    unsigned long hash = 2166136261u;
    for (char c : str) {
        hash ^= static_cast<unsigned char>(c);
        hash *= 16777619u;
    }
    return num_buckets ? (hash % num_buckets) : hash;
}

// source: https://www.partow.net/programming/hashfunctions/
unsigned long jenkins_hash(const std::string& str, int num_buckets) {
    unsigned long hash = 0;
    for (char c : str) {
        hash += static_cast<unsigned char>(c);
        hash += (hash << 10);
        hash ^= (hash >> 6);
    }
    hash += (hash << 3);
    hash ^= (hash >> 11);
    hash += (hash << 15);
    return num_buckets ? (hash % num_buckets) : hash;
}

// source: https://github.com/aappleby/smhasher
unsigned long murmur_hash(const std::string& str, int num_buckets) {
	uint32_t seed = 0;
    const uint32_t m = 0x5bd1e995;
    const int r = 24;
    uint32_t len = static_cast<uint32_t>(str.size());
    const char* data = str.data();
    uint32_t h = seed ^ len;

    // Process 4-byte chunks
    while (len >= 4) {
        uint32_t k;
        memcpy(&k, data, sizeof(k));  // Safe alignment-independent load
        
        k *= m;
        k ^= k >> r;
        k *= m;
        
        h *= m;
        h ^= k;
        
        data += 4;
        len -= 4;
    }

    // Handle remaining bytes
    switch (len) {
        case 3: h ^= static_cast<unsigned char>(data[2]) << 16;
        case 2: h ^= static_cast<unsigned char>(data[1]) << 8;
        case 1: h ^= static_cast<unsigned char>(data[0]);
                h *= m;
    }

    // Final mixing
    h ^= h >> 13;
    h *= m;
    h ^= h >> 15;

    return num_buckets ? (h % num_buckets) : h;
}

#endif