Today, Perl turns 25: happy birthday Perl! There’s too much to say about this
language, its philosophy, its culture, … So here, I would just thank all
people who make Perl a success, for such a long time.

## Introduction

A formula is “an entity constructed using the _symbols_ and formation _rules_
of a given _language_“, according to
[Wikipedia](http://en.wikipedia.org/wiki/Formula) as of this writing. These
words sound really familiar for any Perl 6 users who have already played with
[grammars](http://perl6advent.wordpress.com/2009/12/24/day-24-the-perl-6
-standard-grammar/), however this is not the purpose of this article. Instead,
the aim is to demonstrate how the [Perl 6](http://perl6.org/) language can be
easily extended in order to use formulas **literally** in the code.

There are many domains, like Mathematics, Physics, finance, etc., that use
their own specific languages. When writing programs for such a domain, it
could be less error-prone and simpler to use its specific language instead of
using a specific API. For example, someone who has knowledge in electronic may
find the formula below:

    
    4.7kΩ ± 5%

far more understandable than the following piece of code:

    
    my $factory MeasureFactory.getSharedInstance();
    my $resistance = $factory.createMeasure(value     => 4700,
                                            unit      => Unit::ohm,
                                            precision => 5);

The formula `4.7kΩ ± 5%` will be used all along this article as an example.

## Symbol `k`: return a modified value

Let’s start with the simplest symbol: `k`. Basically this is just a multiplier
placed after a numeric value. To make the Perl 6 language support this new
operator, there’s no need to know much about Perl 6 guts: operators are just
funny looking sub-routines:

    
    sub postfix:<k> ($a) is tighter(&infix:<*>) { $a * 1000 }

This just makes `4.7k` return `4.7 * 1000`, for example. To be a little bit
picky, such kind of multiplier should not be used without a unit (ex. `Ω`) and
not be coupled to another multiplier (ex. `μ`). This would have made this
article a little bit more complex, so this is left as an exercise to the
reader :) Regarding the `tighter` trait, it is already well explained in
[three](http://perl6advent.wordpress.com/2009/12/22/day-22-operator-
overloading/) [other ](http://perl6advent.wordpress.com/2011/12/22/day-22
-operator-overloading-
revisited/)[articles](http://perl6advent.wordpress.com/2012/12/16/day-16
-operator-precedence/).

## Symbols `%`: return a closure

The next symbol is `%`: it is commonly used to compute a ratio of _something_,
that’s why `5%` shouldn’t naively be transformed into `0.05`. Instead, it
creates a closure that computes the given percent of
[whatever](http://perl6advent.wordpress.com/2012/12/03/day-3-whatever-the-
layout-manager-is/) you want:

    
    sub postfix:<%> ($a) is tighter(&infix:<*>) { * * $a / 100 }

It’s now possible to write `$f = 5%; $f(42)` or `5%(42)` directly, and this
returns `2.1`. It is worth saying this doesn’t conflict with the `infix:<%>`
operator (modulo), that is, `5 % 42` still returns `5`.

## Symbol `Ω`: create a new `Measure` object

Let’s go on with the `Ω` symbol. One possibility is to tie the unit and the
value in the same object, as in the `Measure` class defined below. The
`ACCEPTS` method is explained later but the idea in this case is that two
`Measure` objects with two different units can’t match together:

    
    enum Unit <volt ampere ohm>;
    
    class Measure {
        has Unit $.unit;
        has $.value;
    
        method ACCEPTS (Measure:D $a) {
            $!unit == $a.unit && $!value.ACCEPTS($a.value);
        }
    }

Then, one operator per unit can be defined in order to _hide_ the underlying
API, that is, to allow `4.7kΩ` as an equivalent of `Measure.new(value => 4.7k,
unit => ohm)`:

    
    sub postfix:<V> (Real:D $a) is looser(&postfix:<k>) {
        Measure.new(value => $a, unit => volt)
    }
    sub postfix:<A> (Real:D $a) is looser(&postfix:<k>) {
        Measure.new(value => $a, unit => ampere)
    }
    sub postfix:<Ω> (Real:D $a) is looser(&postfix:<k>) {
         Measure.new(value => $a, unit => ohm)
    }

Regarding the `ACCEPTS` method, it is used by `~~`, the smartmatch operator,
to check if the left operand can _match_ the right operand, the one with the
`ACCEPTS` method. In other terms, `$a ~~ $b` is equivalent to
`$b.ACCEPTS($a)`. Typically, this allows the _intuitive_ comparison between
two different types, like scalars and containers for example.

In this example, this method is overloaded to ensure two `Measure `objects can
match only if they have the same unit and if their values match. That means
`4kΩ ~~ 4.0kΩ` is `True` whereas `4kΩ ~~ 4kV` is `False`. Actually, there are
many units that _can_ mix altogether, typically currencies (¥€$) and the ones
[derived](http://en.wikipedia.org/wiki/SI_derived_unit) from the International
System of Unit. But as usual, when something is a little bit more complex, it
is left as an exercise to the reader ;)

## Symbol `±`: create a `Range` object

There’s only one symbol left so far: `±`. In the example, it is used to
indicate the [tolerance](http://en.wikipedia.org/wiki/Electronic_color_code)
of the resistance. This tolerance could be either absolute (expressed in `Ω`)
or relative (expressed in `%`), thus the new `infix:<±>` operator has several
signatures and have to be declared with a `multi` keyword. In both cases, the
`value` is a new `Range` objects with the right bounds:

    
    multi sub infix:<±> (Measure:D $a, Measure:D $b) is looser(&postfix:<Ω>) {
        die if $a.unit != $b.unit;
        Measure.new(value => Range.new($a.value - $b.value,
                                       $a.value + $b.value),
                    unit => $a.unit);
    }
    
    multi sub infix:<±> (Measure:D $a, Callable:D $b) is looser(&postfix:<Ω>) {
        Measure.new(value => Range.new($a.value - $b($a.value),
                                       $a.value + $b($a.value)),
                    unit => $a.unit);
    }

Actually, any `Callable` object could be used in the second variant, not only
the closures created by the `%` operators.

So far, so good! It’s time to check in the Perl6 REPL interface if everything
works fine:

    
    > 4.7kΩ ± 1kΩ
    Measure.new(unit => Unit::ohm, value => 3700/1..5700/1)
    
    > 4.7kΩ ± 5%
    Measure.new(unit => Unit::ohm, value => 4465/1..4935/1)

It looks good, so all the code above ought to be moved into a dedicated
[module](http://perl6advent.wordpress.com/2009/12/12/day-12-modules-and-
exporting/) in order to be re-used at will. Then, a customer could load it and
write literally:

    
    my $resistance = 4321Ω;
    die "resistance is futile" if !($resistance ~~ 4.7kΩ ± 5%);

As of this writing, this works both in
[Niecza](https://github.com/sorear/niecza) and [Rakudo](http://rakudo.org/),
the two most advanced implementations of Perl 6.

## Symbols that aren’t operators

Symbols in a formula are not always operators, they can be symbolic constants
too, like π. In many languages, constants are just _read-only variables_,
which sounds definitely weird: a variable isn’t supposed to be … variable? In
Perl 6, a constant can be a read-only variable too (hmm) or a _read-only term_
(this sounds better). For example, to define the constant term `φ`:

    
    constant φ = (1 + sqrt(5)) / 2;

## Conclusion

In this article the Perl 6 language was slightly extended with several new
_symbols_ in order to embed simple formulas. Although it is possible to go
further by changing the Perl 6 grammar in order to embed more specific
languages, that is, languages that don’t have the same grammar rules. Indeed,
there are already two such languages supported by Perl 6: regexp and
[quotes](http://perl6advent.wordpress.com/2012/12/10/day-10-dont-quote-me-on-
it/). The same way, Niecza use a
[custom](https://github.com/sorear/niecza/blob/v24/docs/nam.pod) language to
connect its portable parts to the unportable.

## Bonus: How to type these exotic symbols?

Most of the Unicode symbols can be type in Xorg — the most used interface
system on Linux — thanks to the `Compose` key, also named `Multi` key. When
this special key is pressed, all the following key-strokes are somewhat merged
in order to [compose](http://en.wikipedia.org/wiki/Compose_key) a symbol.

There’s plenty of documentation about this support elsewhere on Internet, so
only the minimal information is provided here. First, to map the `Compose` key
to the `Caps Lock` key, write in a X terminal:

    
    sh> setxkbmap -option compose:caps

Some compositions are likely already defined, for instance `<caps>` followed
by `+` then `-` should now produce `±`, but both `Ω` and `φ` are likely not
defined. One solution is to write a

`~/.XCompose` file with the following content:

    
    include "%L" # Don't discard the current locale setting.
    
    <Multi_key> <o> <h> <m>      : "Ω"  U03A9
    <Multi_key> <O> <underscore> : "Ω"  U03A9
    <Multi_key> <underscore> <O> : "Ω"  U03A9
    
    <Multi_key> <p> <h> <y> : "φ"  U03C6
    <Multi_key> <o> <bar>   : "φ"  U03C6
    <Multi_key> <bar> <o>   : "φ"  U03C6

This takes effect for each newly started applications. Feel free to leave a
comment if you know how to add such a support on other

systems.

