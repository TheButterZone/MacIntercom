#include <stdio.h>
#include <stdlib.h>

void rtc_FatalMessage(const char* file, int line, const char* msg) {
    fprintf(stderr, "FATAL ERROR in %s:%d - %s\n", file, line, msg);
    abort();
}
