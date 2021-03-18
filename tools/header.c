#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char stdin_line[BUFSIZ];
char file_line[BUFSIZ];
char * element_name;
char * path;

static void parseline(const char * line) {
	int i = 0;

	if (element_name) {
		for (; line[i] == element_name[i]; ++i);

		if (line[i] == ':' && element_name[i] == '\0') {
			printf("%s\t", path);

			for (++i; line[i]; ++i) {
				putc(line[i], stdout);
			}
		}
	} else {
		printf("%s\t", path);
		for (; line[i] != ':' && line[i]; ++i) { putc(line[i], stdout); };

		putc('\t', stdout);

		for (++i; line[i]; ++i) {
			putc(line[i], stdout);
		}
	}
}

static void readfile() {
	FILE * file = fopen(path, "r");
	int is_header = 0;

	while (fgets(file_line, BUFSIZ, file)) {
		if (strcmp(file_line, "---\n") == 0) {
			if (is_header)
				break;
			is_header = 1;
		} else if (is_header) {
			parseline(file_line);
		}
	}

	fclose(file);
}

int main(int argc, char ** argv) {
	if (argc != 2) {
		element_name = NULL;
	} else {
		element_name = argv[1];
	}

	while(fgets(stdin_line, BUFSIZ, stdin)) {
		path = stdin_line;
		for (; *path != '\n'; ++path);
		*path = '\0';
		path = stdin_line;

		readfile();
	}

	return 0;
}
