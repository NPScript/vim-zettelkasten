#include <stdlib.h>
#include <stdio.h>
#include <string.h>

char filepath[BUFSIZ];
char fline[BUFSIZ];
char * pattern;
int is_header;

static int line_contains_pattern(char * line) {
	char * c = pattern;
	char * l = line;

	for (; *c && *l; ++l) {
		if (*c == *l)
			++c;
		else
			c = pattern;
	}

	return !*c;
}

static int file_contains_pattern() {
	FILE * file = fopen(filepath, "r");
	is_header = 0;

	while (fgets(fline, BUFSIZ, file)) {
		if (strcmp(fline, "---\n") ==  0) {
			is_header = !is_header;
			continue;
		}

		if (!is_header) {
			if (line_contains_pattern(fline))
				return 1;
		}
	}

	fclose(file);

	return 0;
}

int main(int argc, char ** argv) {
	if (argc != 2) {
		fprintf(stderr, "csearch [pattern]\n");
		return -1;
	}

	pattern = argv[1];

	while (fgets(filepath, BUFSIZ, stdin)) {
		char * c;
		for (c = filepath; *c != '\n'; ++c);
		*c = 0;
		if (file_contains_pattern())
			printf("%s\n", filepath);
	}

	return 0;
}
