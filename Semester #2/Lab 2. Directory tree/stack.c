#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include "stack.h"

// Создаем стек
stack* createStack(int size)
{
    stack* st = calloc(1, sizeof(stack));
	if (st == NULL)
	{
			printf("Error in calloc st!\n");
			return NULL;
	}

    st->alloc = size;
    st->arr = calloc(size, sizeof(char*));
	if (st->arr == NULL)
	{
		printf("Error in calloc st->arr!\n");
		return NULL;
	}

    for (int i = 0; i < size; i++)
    {
        st->arr[i] = calloc(PATH_MAX, sizeof(char));
		if (st->arr[i] == NULL)
		{
			printf("Error in calloc st->arr[i]! createStack().\n");
		}
    }

    st->len = 0;
	st->step = 2;

    return st;
}

// Чистим память
void freeStack(stack* st)
{
    for (int i = 0; i < st->len; i++)
    {
        free(st->arr[i]);
    }
    free(st->arr);
    free(st);
}

// Засовываем в стек
int pushStack(stack *st, const char *str)
{
    strcpy(st->arr[st->len++], str);
    
    if (st->len >= st->alloc)
    {
		st->alloc *= st->step;
		st->arr = realloc(st->arr, st->alloc*sizeof(char*));
		if (st->arr == NULL)
		{
			printf("Error in realloc!\n");
			return -1;
		}

		for (int i = st->len; i < st->alloc; i++)
    	{
        	st->arr[i] = calloc(PATH_MAX, sizeof(char));
			if (st->arr[i] == NULL)
			{
				printf("Error in calloc st->arr[i]! pushStack().\n");
			}
    	}
    }

	return 0;
}

// Вытаскиваем из стека
const char* pullStack(stack *st)
{
    if (st->len == 0)
    {
        return NULL;
    }

    char *str = calloc(strlen(st->arr[st->len-1]), sizeof(char));
    strcpy(str, st->arr[--st->len]);

    return str;
}