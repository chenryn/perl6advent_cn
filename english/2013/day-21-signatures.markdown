## Day 21 – Signatures

by [coke][4]

In today’s post, we’ll go through the basics of Perl 6′s subroutine signatures, which allow us to declare our parameters instead of coding them as we do in Perl 5.

In Perl 5, arguments to a sub are accessible via the @\_ array, so if you want to access an argument to a sub, you can either access the array directly (which is typically only done where speed is a concern)…

    use v5;
    sub greet {
        print "Hello, " . @_[0] . "\n";
    }

Or, more commonly, pull off any arguments as lexicals:

    use v5;
    sub greet {
        my $name = shift @_;
        print "Hello, $name\n";
    }

## Positionals

Perl 6 lets you declare required positional arguments for your subs as part of the signature:

    use v6;
    sub greet($name) {
        print "Hello, $name\n";
    }

Inside the sub, `$name` is available as a readonly alias to the passed in variable.

By default, parameters are required. If you try to call this function with no parameters as `greet`, you’ll get a compile time error:

    ===SORRY!===
    CHECK FAILED:
    Calling 'greet' requires arguments (line 1)
    Expected: :($name)

You can make the parameter optional by adding a `?` to the signature. Then you’ll have to examine the parameter to see if a defined value was passed in. Or, you can declare a default value to be used if none is passed in:

    use v6;
    sub guess($who, $what?) {
        # manually check to see if $what is defined
    }
    
    sub dance($who, $dance = "Salsa") {
        ...
    }
    dance("Rachael")
    dance("Rachael", "Watusi")

Another way to handle optional arguments is to use multis. Multis are subs that can have multiple implementations that differ by their signature. When invoking a multi, the argument list used in the invocation is used to determine which version of the multi to dispatch to.

    use v6;
    multi sub dance($who, $dance) {
        say "$who is doing the $dance";
    }
    multi sub dance($who) {
        dance($who, "Salsa");
    }

## Types

The parameters in the previous section allow any type of value to be passed in. You can declare that only certain types are valid:

    sub greet(Str $name) {
        say "hello $name";
    }

Now `hello("joe")` will work as it did before. But `hello(3)` will generate a compile time error:

    ===SORRY!===
    CHECK FAILED:
    Calling 'greet' will never work with argument types (int) (line 1)
    Expected: :(Str $name)

In addition to any of Perl 6 builtin types or user-built classes, you can also add programmatic checks inline in the signature with `where` clauses.

    use v6;
    multi odd-or-even(Int $i where * %% 2) { say "even" };
    multi odd-or-even(Int $i) { say "odd"};

Note that we didn’t have to add a where clause to the second sub. The multi-dispatch algorithm will prefer the more detailed signature when it matches, but fallback to the less descriptive version when it doesn’t.

You can even use literal values as arguments. This style allows you to move some of your logic to the multi dispatcher.

    use v6;
    multi fib(1) { 1 }
    multi fib(2) { 1 }
    multi fib(Int $i) { fib($i-1) + fib($i-2) }
    
    say fib(10);

Note that this isn’t very efficient… yet. Once the `is cached` trait for subs is implemented, we can use that to provide a builtin analog to Perl 5′s `Memoize` module.

## Named

Perl 6 provides for named parameters; if the positionals are analogous to an array of parameters, the named arguments are like a hash. You use a preceding colon in the argument declaration, and then pass in a pair for each parameter when invoking the sub.

    use v6;
    sub doctor(:$number, :$prop) {
        say "Doctor # $number liked to play with his $prop";
    }
    doctor(:prop("cricket bat"), :number<5>);
    doctor(:number<4>, :prop<scarf>);

Note that the order the parameters are passed in doesn’t matter for named parameters.

If you have a variable of the same name in the calling scope, you can simplify the calling syntax to avoid creating an explicit pair.

    use v6;
    my $prop = "fez";
    my $number = 11;
    doctor(:$prop, :$number)

You can also use different names internally (using the expanded pair syntax) for the named arguments. This allows you to use different (simplified or sanitized) versions for the caller.

    use v6;
    sub doctor(:number($incarnation), :prop($accoutrement)) {
        say "Doctor # $incarnation liked to play with his $accoutrement";
    }
    my $number = 2;
    my $prop = "recorder";
    doctor(:$number, :$prop)

## Slurpy

To support functions like `sprintf`, we need to be able to take a variable number of arguments. We call these args “slurpy”, since they “slurp” up the arguments.

    # from rakudo's src/core/Cool.pm
    sub sprintf(Cool $format, *@args) {
        ...
    }

When invoking this sub, the first argument must be of type Cool (kind of a utility supertype), and all the remaining positional arguments are slurped up into the `@args` variable. The preceding `*` indicates the slurp.

Symmetrically, we can also slurp up named arguments into a hash.

    # from rakudo's src/core/control.pm
    my &callwith := -> *@pos, *%named {
        ...
    }

This snippet introduces to the pointy block syntax for anonymous subs. The `->` begins the declaration, followed by the signature (without parentheses), and finally the sub definition in the block. The signature here shows all the positionals ending up in `*@pos`, and all the named arguments in `%named`.

This also shows that positionals and named arguments can be combined in the same sub.

## Methods

Method and sub declarations are virtually identical. All the parameters mentioned so far are usable in methods.

The main difference is that methods can be passed an invocant (the object associated with the method call), and when you define the sub, you have the opportunity to name it. It must be the first parameter if present, and is marked with a trailing `:`.

    use v6;
    method explode ($self: $method) {...}

Note that there is no comma separating these the invocant and the first positional. In this context, the colon functions as a comma.

## Parameter Traits

Each parameter can additionally specify a trait that changes the behavior of that parameter:

* `is readonly` - this is the default behavior for a parameter; the sub cannot modify the passed in value.
* `is rw` - the argument can be modified. Forces the argument to be required.
* `is copy` - the sub gets a modifiable copy of the original value.

## More Information

Check out [Synopsis #6][5] for more information, and the [roast test suite][6] for more examples – any of the directories starting with `S06-`.


![][39]

  [4]: https://perl6advent.wordpress.com/author/wcoleda/ "View all posts by coke"
  [5]: http://perlcabal.org/syn/S06.html
  [6]: https://github.com/perl6/roast
