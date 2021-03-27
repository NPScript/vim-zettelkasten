#include <stdio.h>
#include <dirent.h>
#include <string.h>

char * search_pattern;

int contains_pattern(const char * string, const char * pattern) {
	int contains;
	int i;
	int j;
	int ps = strlen(pattern);
	int ds = strlen(string) - ps + 1;

	for (i = 0; i < ds; ++i) {
		contains = 1;
		for (j = 0; j < ps; ++j) {
			if (string[i + j] != pattern[j]) {
				contains = 0;
				break;
			}
		}

		if (contains)
			return 1;
	}

	return 0;
}

void search(const char * path) {
	DIR * dir = opendir(path);
	struct dirent * ent;
	char path_name[2048];

	if (dir != NULL) {
		while ((ent = readdir(dir)) != NULL) {
			if (strcmp(ent->d_name, ".") != 0 && strcmp(ent->d_name, "..") != 0) {
				if (contains_pattern(ent->d_name, search_pattern))
					printf("%s/%s\n", path, ent->d_name);
				if (ent->d_type == DT_DIR) {
					strcpy(path_name, path);
					strcat(path_name, "/");
					strcat(path_name, ent->d_name);
					search(path_name);
				}
			}
		}
	}

	closedir(dir);
}

int main(int argc, char ** argv) {
	if (argc == 2) {
		search_pattern = "";
		search(argv[1]);
	} else if (argc == 3) {
		search_pattern = argv[2];
		search(argv[1]);
	} else {
		search_pattern = "";
		search(".");
	}

	return 0;
}
