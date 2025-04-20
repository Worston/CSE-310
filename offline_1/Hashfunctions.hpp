#ifndef HASHFUNCTIONS_H
#define HASHFUNCTIONS_H

#include <string>

static unsigned long SDBMHash(const std::string str, int num_buckets) {
	unsigned long hash = 0;
	unsigned int i = 0;
	unsigned int len = str.length();

	for (i = 0; i < len; i++){
		hash = (str[i]) + (hash << 6) + (hash << 16) - hash;
		hash = hash % num_buckets;
	}

	return hash;
}


#endif