#include <sys/stat.h>

/* Stubs for unimplemented syscalls */
int _close(int fd) { return 0; }
int _fstat(int fd, struct stat *st) { return 0; }
int _isatty(int fd) { return 0;}
int _lseek(int fd, int ptr, int dir) { return 0;}
int _read(int fd, void *buf, size_t len) { return 0;}
int _write(int fd, const void *buf, size_t len) { return 0; }
