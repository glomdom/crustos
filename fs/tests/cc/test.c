/* test a few simple C constructs */

// just return a constant
int retconst() {
    return 42;
}

// test unary op and that we don't require whitespace around symbols
int neg() { return -$2a; }
int bwnot() {
    return ~'*';
}

// test binop precedence
int exprbinops() {
    return 1 + 2 * 3;
}

int binopand() {
    return $ff & 42;
}

int binopor() {
    return 40 | 2;
}

int binopxor() {
    return 43 ^ 1;
}

int binopshl() {
    return 42 << 3;
}

int binopshr() {
    return 42 >> 2;
}

// test some bug i was having
int binop1(int a, int b) {
    int c;
    c = a ^ b;

    return c;
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

void pushpop() {
    pspush(pspop());
}

int adder(int a, int b) {
    return a + b;
}

int subber(int a, int b) {
    return a - b;
}

// are arguments, both constants and lvalues, properly passed?
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
    int* b = &a;
    *b = 54;

    return a;
}

int condif(int x) {
    if (x == 42) {
        x = x+100;
    } else {
      x = x+1;
    }

    return x;
}

// test that ++ and -- modify the lvalue directly
int incdec(int x) {
    ++x;
    --x;

    return ++x;
}

// test that the final "--" doesn't affect the result
int incdecp(int x) {
    x++;
    x--;

    return ++x--;
}

// test that parens override precedence
int exprparens() {
    return (1 + 2) * 3;
}

// test that a void function doesn't add anything to PS
void cnoop() {}

// test that pointer arithmetics properly multiply operands by 2 or 4.
int* ptrari(int *x) {
    return x + 1;
}

int array() {
    int a[3] = {42, 12, 2};
    return *a + a[1] - *(a+2);
}

int global1 = 1234;
int global2[3] = {4, 5, 6};

int global() {
    return global1;
}

// "max" is a forth word defined in the system
int sysword(int a, int b) {
    return max(a, b);
}

// TODO: the effect would be better with stype(), but unfortunately, because
// stype doesn't return an argument, the stackframe is broken when we call it.
// When we begin supporting C signature in forth word annotations, then we can
// revisit this and call stype().
int helloworld() {
    return "Hello, World!";
}

// Now let's put all this together an start calling fancy forth words!
int isinrange(int n, int l, int h) {
    return find("=><=")(n, l, h);
}

int forloop(int a, int b) {
    int i;
    for (i=0; i<b; i++) {
        a++;
    }
    return a;
}