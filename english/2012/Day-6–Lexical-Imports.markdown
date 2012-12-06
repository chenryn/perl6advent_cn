Perl 6 is built on lexical scopes. Variables, subroutines, constants and even types are looked up lexically first, and subroutines are only looked up in lexical scopes.

So it is only fitting that importing symbols from modules is also done into lexical scopes. I often write code such as

    use v6;

    # the main functionality of the script
    sub deduplicate(Str $s) {
        my %seen;
        $s.comb.grep({!%seen{ .lc }++}).join;
    }

    # normal call
    multi MAIN($phrase) {
        say deduplicate($phrase)
    }

    # if you call the script with --test, it runs its unit tests
    multi MAIN(Bool :$test!) {
        # imports &plan, &is etc. only into the lexical scope
        use Test;
        plan 2;
        is deduplicate('just some words'), 'just omewrd', 'basic deduplication';
        is deduplicate('Abcabd'), 'Abcd', 'case insensitivity';
    }

This script removes all but the first occurrence of each character given on the command line:

    $ perl6 deduplicate 'Duplicate character removal'
    Duplicate hrmov

But if you call it with the --test option, it runs its own unit tests:

    $ perl6 deduplicate --test
    1..2
    ok 1 - basic deduplication
    ok 2 - case insensitivity

Since the testing functions are only necessary in a part of the program — in a lexical scope, to be more precise –, the use statement is inside that scope, and limits the visibility of the imported symbols to this scope. So if you try to use the is function outside the routine in which Test is used, you get a compile-time error.

Why, you might ask? From the programmer's perspective, it reduces risk of (possibly unintended and unnoticed) name clashes the same way that lexical variables are safer than global variables.

From the point of view of language design, the combination of lexical importing, runtime-immutable lexical scopes and lexical-only lookup of subroutines allows resolving subroutine names at compile time, which again allows neat stuff like detecing calls to undeclared functions, compile-time type checking of arguments, and other nice optimizations.

But subroutines are only the tip of the iceberg. Perl 6 has a very flexible syntax, which you can modify with custom operators and macros. Those too can be exported, and imported into lexical scopes. Which means that language modifications are also lexically by default. So you can safely load any language-modifying extension, without running into danger that a library you use can't cope with it — the library doesn't even see the language modification.

So ultimately, lexical importing is another facet of encapsulation.
