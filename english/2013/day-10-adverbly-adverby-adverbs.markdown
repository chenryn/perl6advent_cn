## Day 10 — Adverbly Adverby Adverbs

by [lueinc][4]

So yesterday masak introduced and covered quite well `Hash` objects, and the things that go inside them, `Pair`s. Here _quickly_ are the two ways you can create `Pair` objects: there’s fat arrow notation,

    my %h = debug =&gt; True;

and there’s colonpair notation:

    my %h = :debug(True);

Today I’ll show you how the colonpair notation in particular is so useful, Perl 6 uses them as a major language feature.

## What are Adverbs?

Adverbs in natural languages change in slight ways the meaning of verbs and adjectives. For example,

The dog fetched the stick.

is a simple statement of something the dog did. By adding an adverb, such as:

The dog quickly fetched the stick.

clarifies that dog was able to do this within a short amount of time. Adverbs can make more drastic changes, as seen here:

This batch of cookies was chewy.
This batch of cookies was oddly chewy.

The second sentence, with the “oddly” adverb, lets you know that chewy cookies were not the goal of the baker, while the first sentence _alternately_ does nothing to discredit the efforts of the cook.

Adverbs in Perl 6 perform much of the same tasks, telling functions and other language features to do what they’re about to do _differently_.

## The Basics of Adverbs

Adverbs are expressed with colonpair syntax. Most often, you’ll use them as on/off switches, though it’s _perfectly_ fine for them to take on non-binary information.

The way you turn on an adverb is like this:

    :adverb

which is the same as

    :adverb(True)

To turn off an adverb, you write

    :!adverb

which is just like

    :adverb(False)

If you’re passing a literal string, such as

    :greet('Hello')
    :person("$user")

you can instead do

    :greet&lt;Hello&gt;
    :person«$user» or :person&lt;&lt;$user&gt;&gt;

as long as there’s no whitespace in the string (the angle bracket forms _actually_ create a list of terms, separating on whitespace, which could _potentially_ break whatever’s given the adverb).

You can also abbreviate variable values if the variable’s name is equal to the key’s name:

    :foo($foo)
    :$foo

And if you’re supplying a decimal number, there’s two ways to do that:

    :th(4)
    :4th

(The :4th form only works on quoting construct adverbs, like m// and q[], in Rakudo at the moment.)

Note that the negation form of adverb (`:!adv`) and the sigil forms (`:$foo, :@baz`) can’t be given a value, because you already gave it one.

## Adverbs in Function Calls

Adverbs used within function calls act more like the named arguments they are than adverbs, but they still count as adverbs.

How do you use adverbs in a function call? Here’s a couple of ways:

    foo($z, :adverbly);
    foo($z, :bar, :baz);
    foo($z, :bar :baz);

Each adverb is a named parameter, so multiple commas separate each adverb, like with any other parameter. Of note is that you’re allowed to “stack” adverbs like you see in the last example (though Rakudo as of yet doesn’t handle this within function calls). You can do this anywhere one adverb is allowed, by the way.

## Adverbs on Operators

Adverbs can be supplied to operators just as they can be to functions. They function at a precedence level tighter than item assignment and looser than conditional. ([See this part of the Synopses for details on precedence levels.][5])

Here are a couple of simple uses of adverbs on operators:

    foo($z) :bar :baz  # equivalent to foo($z, :bar, :baz)
    1 / 3 :round       # applies to /
    $z &amp; $y :adverb    # applies to &amp;

When it comes to more complex cases, it’s helpful to remember that adverbs work similar to how an infix operator at that precedence level would (if it helps, think of the colon as a double bond in chemistry, binding both “sides” of the infix to the left-hand side). It operates on the loosest precedence operator no looser than adverbs.

    1 || 2 &amp;&amp; 3 :adv   # applies to ||
    1 || (2 &amp;&amp; 3 :adv) # applies to &amp;&amp;
    !$foo.bar() :adv   # applies to !
    !($foo.bar() :adv) # applies to .bar()
    @a[0..2] :kv       # applies to []
    1 + 2 - 3 :adv     # applies to -
    1 \*\* 2 \*\* 3 :adv   # applies to the leftmost \*\*

Notice that the behavior of adverbs on operators looser than adverbs is _currently_ undefined.

    1 || 2 and 3 :adv  # error ('and' too loose, applies to 3)
    1 and 2 || 3 :adv  # applies to ||

## Adverbs on Quoting Constructs

Various quote-like constructs change behavior through adverbs as well.

(Note: this post will refrain from providing an exhaustive list of potential adverbs. S02 and S05 are good places to see them in more detail.)

For example, to have a quoting construct that functions like single quotes but also interpolates closures, then you would do something like:

    q:c 'Hello, $name. You have \{ +@msgs \} messages.' # yes, a space between c and ' is required

Which comes out as

Hello, $name. You have 12 messages.

(This implies your `@msgs` array has 12 elements.)

If you instead just wanted a double-quote-like construct that didn’t interpolate scalars, you’d do

    qq:!s ' ... etc ...'

Regexes allow you to use adverbs within the regex in addition to outside. This allows you to access features brought by those adverbs in situations where you’d otherwise be unable to use them.

    $a ~~ m:i/HELLO/; # matches HELLO, hello, Hello ...
    $a ~~ /:i HELLO/; # same
    regex Greeting \{
        :i HELLO
    \}                 # same

One thing to keep in mind is that adverbs on a quoting construct must use parentheses to pass values. This is because _normally_ any occurrence of brackets after an adverb is considered to be passing a value to that adverb, which conflicts with you being able to choose your own quoting brackets.

    m:nth(5)// # OK
    m:nth[5]// # Not OK
    q:to(EOF)  # passing a value to :to, no delimiters found
    q:to (EOF) # string delimited by ()

## Your Very Own Adverbs

So you’ve decided you want to make your own adverbs for your function. If you’ll remember, adverbs and named arguments are almost the same thing. So to create an adverb for your function, you just have to declare named parameters:

    sub root3($number, :$adverb1, :$adverb2) \{
        # ... snip ...
    \}

Giving adverbs a default value is the same as positional parameters, and making an adverb required just needs a `!` after the name:

    sub root4($num, :$adv1 = 42, :$adv2, :$adv3!) \{
        # default value of $adv1 is 42,
        # $adv2 is undefined (boolifies to False)
        # $adv3 must be supplied by the user
    \}

If you want to catch all the adverbs somebody throws at you, you can use a slurpy hash:

    sub root3($num, \*%advs) \{
        # %advs contains all the :adverbs
        # that were passed to the function.
    \}

And if you define named parameters for the `MAIN` sub, they become commandline options! This is the one time where you should use `Bool` on boolean named parameters, even if you don’t _normally_, just to keep the option from accepting a value on the commandline.

It’s the same for operators, as operators are just functions with funny syntax.

Now that you learned how to apply the humble `Pair` to much more than just `Hash`es, I hope you’ll _quickly_ start using them in your code, and _joyously_ read the rest of the advent!


![][59]

  [4]: https://perl6advent.wordpress.com/author/lueinc/ "View all posts by lueinc"
  [5]: http://perlcabal.org/syn/S03.html#Operator_precedence
