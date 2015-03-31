#include <stdio.h>

#include "version.h"

int main(char ** argv, int argc) {
	printf("Hello world, this is v%s\n", MYAPP_VERSION);
}
