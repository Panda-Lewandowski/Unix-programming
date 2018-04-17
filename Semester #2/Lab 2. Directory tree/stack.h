#ifndef STACK_H
#define STACK_H

typedef struct stack
{
    char **arr;
    int len;
    int alloc;
	int step;
} stack;

stack* createStack(int size);
void freeStack(stack* st);
int pushStack(stack *st, const char *str);
const char* pullStack(stack *st);

#endif