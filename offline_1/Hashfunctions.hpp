#ifndef HASHFUNCTIONS_H
#define HASHFUNCTIONS_H

#include <string>

static unsigned int SDBMHash(const std::string str) {
	unsigned int hash = 0;
	unsigned int i = 0;
	unsigned int len = str.length();

	for (i = 0; i < len; i++){
		hash = (str[i]) + (hash << 6) + (hash << 16) - hash;
	}

	return hash;
}


#endif