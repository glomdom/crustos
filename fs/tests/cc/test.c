/* test a few simple C constructs */

#[ 42 const MYCONST ]#

// just return a constant
extern int retconst() {
    return #[ MYCONST c]# ;
}

// test unary op and that we don't require whitespace around symbols
extern int neg() { return -$2a; }
extern int bwnot() {
    return ~'*';
}

// test binop precedence
extern int exprbinops() {
    return 1 + 2 * 3;
}

extern int binopand() {
    return $ff & 42;
}

extern int binopor() {
    return 40 | 2;
}

extern int binopxor() {
    return 43 ^ 1;
}

extern int binopshl() {
    return 42 << 3;
}

extern int binopshr() {
    return 42 >> 2;
}

// test some bug i was having
extern int binop1(int a, int b) {
    int c;
    c = a ^ b;

    return c;
}

extern int boolops() {
    return 66 < 54 && 2 == 2;
}

extern int variables() {
    unsigned int foo = 40, _bar = 2;
    _bar = foo + _bar;

    return foo + _bar;
}

extern int funcall() {
    return retconst();
}

extern void pushpop() {
    pspush(pspop());
}

int adder(int a, int b) {
    return a + b;
}

extern int subber(int a, int b) {
    return a - b;
}

// are arguments, both constants and lvalues, properly passed?
extern int plusone(int x) {
    return adder(1, x);
}

extern int ptrget() {
    int a = 42;
    int *b = &a;

    return *b;
}

extern int ptrset() {
    int a = 42;
    int* b = &a;
    *b = 54;

    return a;
}

extern int condif(int x) {
    if (x == 42) {
        x = x+100;
    } else {
      x = x+1;
    }

    return x;
}

// test that ++ and -- modify the lvalue directly
extern int incdec(int x) {
    ++x;
    --x;

    return ++x;
}

// test that the final "--" doesn't affect the result
extern int incdecp(int x) {
    x++;
    x--;

    return ++x--;
}

// test that parens override precedence
extern int exprparens() {
    return (1 + 2) * 3;
}

// test that a void function doesn't add anything to PS
extern void cnoop() {}

// test that pointer arithmetics properly multiply operands by 2 or 4.
extern int* ptrari(int *x) {
    return x + 1;
}

extern int array() {
    int a[3] = {42, 12, 2};
    
    return *a + a[1] - *(a+2);
}

int global1 = 1234;
int global2[3] = {4, 5, 6};

extern int global() {
    return global1;
}

// "max" is a forth word defined in the system
extern int sysword(int a, int b) {
    max(a, b);

    return pspop();
}

extern void helloworld() {
    stype("Hello, World!");
}

// Now let's put all this together an start calling fancy forth words!
// Here we see the power of macros in action. Let's say we're trying to call
// the system word `=><=`. It's not a valid C identifier, so we use macros
// to trick the parser into accepting it.
extern int isinrange(int n, int l, int h) {
    #[ S" =><=" i]# (n, l, h);

    return pspop();
}

extern int forloop(int a, int b) {
    int i;

    for (i=0; i<b; i++) {
        a++;
    }

    return a;
}