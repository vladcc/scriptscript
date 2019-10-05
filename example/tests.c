// machine generated file
#include <stdio.h>
#include <math.h>
#include <stdlib.h>

int intfact(int n)
{
	if (n < 0 || n > 12) return -1;
	if (n < 2) return 1;
	return n * intfact(n-1);
}

int intsqrt(int n)
{
	if (n < 0) return -1;
	double sqroot = sqrt(n);
	if (fabs(floor(sqroot)) == fabs(sqroot)) return sqroot;
	return -2;
}

static void test_intsqrt(void)
{
	typedef struct test_node {
		int input;
		int match_with;
		int match_how;
	} test_node;

	enum {equals = 1, less_than = 2};
	
	test_node test_tbl[] = {
		{.input = 16, .match_with = 4, .match_how = equals},
		{.input = 10, .match_with = 0, .match_how = less_than},
		{.input = 0, .match_with = 0, .match_how = equals},
		{.input = -1, .match_with = 0, .match_how = less_than},
	};

	int result;
	test_node * node;
	for (int i = 0; i < sizeof(test_tbl)/sizeof(*test_tbl); ++i)
	{
		node = test_tbl+i;
		result = intsqrt(node->input);
		switch(node->match_how)
		{
			case equals:
				if (!(result == node->match_with))
				{
					printf("index of failed test: %d\n", i);
					printf("function %s(), line %d\n", __func__, __LINE__);
					printf("input %d, result %d, expected equals %d\n", node->input, result, node->match_with);
					exit(EXIT_FAILURE);
				}
				break;
			case less_than:
				if (!(result < node->match_with))
				{
					printf("index of failed test: %d\n", i);
					printf("function %s(), line %d\n", __func__, __LINE__);
					printf("input %d, result %d, expected less_than %d\n", node->input, result, node->match_with);
					exit(EXIT_FAILURE);
				}
				break;
			default:
				break;
		}
	}
}

static void test_intfact(void)
{
	typedef struct test_node {
		int input;
		int match_with;
		int match_how;
	} test_node;

	enum {equals = 1, less_than = 2};
	
	test_node test_tbl[] = {
		{.input = 0, .match_with = 1, .match_how = equals},
		{.input = 1, .match_with = 1, .match_how = equals},
		{.input = 2, .match_with = 2, .match_how = equals},
		{.input = 3, .match_with = 6, .match_how = equals},
		{.input = 4, .match_with = 24, .match_how = equals},
		{.input = 5, .match_with = 120, .match_how = equals},
		{.input = 6, .match_with = 720, .match_how = equals},
		{.input = 12, .match_with = 479001600, .match_how = equals},
		{.input = 13, .match_with = 0, .match_how = less_than},
		{.input = 100, .match_with = 0, .match_how = less_than},
		{.input = -5, .match_with = 0, .match_how = less_than},
	};

	int result;
	test_node * node;
	for (int i = 0; i < sizeof(test_tbl)/sizeof(*test_tbl); ++i)
	{
		node = test_tbl+i;
		result = intfact(node->input);
		switch(node->match_how)
		{
			case equals:
				if (!(result == node->match_with))
				{
					printf("index of failed test: %d\n", i);
					printf("function %s(), line %d\n", __func__, __LINE__);
					printf("input %d, result %d, expected equals %d\n", node->input, result, node->match_with);
					exit(EXIT_FAILURE);
				}
				break;
			case less_than:
				if (!(result < node->match_with))
				{
					printf("index of failed test: %d\n", i);
					printf("function %s(), line %d\n", __func__, __LINE__);
					printf("input %d, result %d, expected less_than %d\n", node->input, result, node->match_with);
					exit(EXIT_FAILURE);
				}
				break;
			default:
				break;
		}
	}
}

int main(void)
{
	test_intsqrt();
	test_intfact();
	return 0;
}
