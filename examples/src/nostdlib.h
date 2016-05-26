

// memcpy and friends.
void  memcpy(void *dest, const void *src, unsigned int num);
void *memmove(void *dest, const void *src, unsigned int num);
void  _bcopy(const void *src, void *dest, unsigned int num);
int   memcmp(const void *a, const void *b, unsigned int num);
void *memset(void *ptr, int value, unsigned int num);
void  strcpy(char *dest, const char *src);
int   strcmp(const char *a, const char *b);
int   strlen(const char *str);

// Very simplistic dynamic memory allocation.
void *malloc(unsigned long size);
void  free(void *ptr);
void *calloc(unsigned long nmemb, unsigned long size);
void *realloc(void *ptr, unsigned long size);

// Misc.
int   min(int a, int b);
int   max(int a, int b);
void  abort(void);

