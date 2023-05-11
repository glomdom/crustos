// test const return
int retconst() {
    return 42;
}

// test unary
int neg() { return -$2a; }

int bwnot() {
    return ~'*';
}

// test binop precedence
int exprbinops() {
    return 1 + 2 * 3;
}

int boolops() {
    return 66 < 54 && 2 == 2;
}

int variables() {
    unsigned int foo = 40;
    unsigned int _bar = 2;
    _bar = foo + _bar;

    return foo + _bar;
}

int funcall() {
    return retconst();
}

int adder(int a, int b) {
    return a + b;
}

// arguments
int plusone(int x) {
    return adder(1, x);
}

int ptrget() {
    int a = 42;
    int *b = &a;

    return *b;
}

int ptrset() {
    int a = 42;
    int *b = &a;

    *b = 54;
    
    return a;
}

int condif(int x) {
    if (x == 42) {
        x = x + 100;
    } else {
        x = x + 1;
    }

    return x;
}

int incdec(int x) {
    ++x;
    --x;

    return ++x;
}

int incdecp(int x) {
    x++;
    x--;

    return ++x--;
}

int exprparens() {
    return (1 + 2) * 3;
}

void cnoop() { return; }

int* ptrari(int* x) {
    return x + 1;
}

int array() {
    int a[3] = {42, 12, 2};

    return *a + a[1] - *(a + 2);
}

/*
    woah a comment test
 */

int global1 = 1234;
int global2[3] = {4, 5, 6};

int global() {
    return global1;
}