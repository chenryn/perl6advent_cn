## All the precedence men

As I was taking a walk today, I realized one of the reasons why I like Perl.
Five as well as six. I often hear praise such as “Perl fits the way I think”.
And I have that feeling too sometimes.

If I were the president (or prime minister, as I’m Swedish), and had a bunch
of advisers, maybe some of them would be yes-men, trying to give me advice
that they think I will want to hear, instead of advice that would be useful to
me. Some languages are like that, presenting us with an incomplete subset of
the necessary tools. The Perl languages, if they were advisers, wouldn’t be
yes-men. They’d give me an accurate view of the world, even if that view would
be a bit messy and hairy sometimes.

Which, I guess, is why Perl five and six are so often used in handling messy
data and turning it into something useful.

To give a few specific examples:

  * Perl 5 takes quotes and quoting _very_ seriously. Not just strings but lists of strings, too. (See the `qw` keyword.) Perl 6 does the same, but takes quoting further. See [see the recent post on quoting](http://perl6advent.wordpress.com/2012/12/10/day-10-dont-quote-me-on-it/).
  * jnthn shows in [yesterday’s advent post](http://perl6advent.wordpress.com/2012/12/15/day-15-phasers-set-to-stun/) that Perl 6 takes compiler phases seriously, and allows us to bundle together code that belongs together conceptually but not temporally. We need to do this because the world is gnarly and running a program happens in phases.
  * Grammars in Perl 6 are not just powerful, but in some sense honest, too. They don’t oversimplify the task for the programmer, because then they would also limit the expressibility. Even though grammars are complicated and intricate, they _should_ be, because they describe a process (parsing) that is complicated and intricate.

## Operators

Perl is known for its many operators. Some would describe it as an “operator-
oriented” language. Where many other language will try to guess how you want
your operators to behave on your values, or perhaps demand that you pre-
declare all your types so that there’ll be no doubt, Perl 6 carries much of
the typing information in its operators:

    
    my $a = 5;
    my $b = 6;
    
    say $a + $b;      # 11 (numeric addition)
    say $a * $b;      # 30 (numeric multiplication)
    
    say $a ~ $b;      # "56" (string concatenation)
    say $a x $b;      # "555555" (string repetition)
    
    say $a || $b;     # 5 (boolean disjunction)
    say $a && $b;     # 6 (boolean conjunction)
    

Other languages will want to bunch together some of these for us, using the
`+` operator for both numeric addition and string concatenation, for example.
Not so Perl. You’re meant to choose yourself, because the choice matters. In
return, Perl will care a little less about the types of the operands, and just
deliver the appropriate result for you.

“The appropriate result” is most often a number if you used a numeric
operator, and a string if you used a string operator. But sometimes it’s more
subtle than that. Note that the boolean operators above actually preserved the
numbers 5 and 6 for us, even though internally it treated them both as true
values. In C, if we do the same, C will unhelpfully “flatten” these results
down to the value 1, its spelling of the value `true`. Perl knows that
truthiness comes in many flavors, and retains the particular flavor for you.

## Operator precedence

“All operators are equal, but some operators are more equal than others.” It
is when we combine operators that we realize that the operators have different
“tightness”.

    
    say 2 * 3 + 1;      # 7, because (2 * 3) + 1
    say 1 + 2 * 3;      # 7, because 1 + (2 * 3), not 9
    

We can always be 100% explicit and surround enough of our operations with
parentheses… but when we don’t, the operators seem to order themselves in some
order, which is not just simple left-to-right evaluation. This ordering
between operators is what we refer to as “precedence”.

No doubt you were taught in math class in school that multiplications should
be evaluated before additions in the way we see above. It’s as if factors
group together closer than terms do. The fact that this difference in
precedence is useful is backed up by centuries of algebra notation. Most
programming languages, Perl 6 included, incorporates this into the language.

By the way, this difference in precedence is found between other pairs of
operators, even outside the realm of mathematics:

    
          Additive (loose)    Multiplicative (tight)
          ================    ======================
    number      +                       *
    string      ~                       x
    bool        ||                      &&

It turns out that they make as much sense for other types as they do for
numbers. And group theory bears this out: these other operators can be seen as
a kind of addition and multiplication, if we squint.

## Operator precedence parser

Deep in the bowels of the Perl 6 parser sits a smaller parser which is very
good at parsing expressions. The bigger parser which parses your Perl 6
program is a really good _recursive-descent_ parser. It works great for
creating syntax trees out of the larger program structure. It works less well
on the level of expressions. Essentially, what trips up a recursive-descent
parser is that it always has to create AST nodes for all the possible
precedence levels, whether they’re present or not.

So this smaller parser is an _operator-table_ parser. It knows what to do with
each type of operator (prefix, infix, postfix…), and kind of weaves all the
terms and operators into a syntax tree. Only the precedence levels actually
used show up in the tree.

The optable parser works by comparing each new operator to the top operator on
a stack of operators. So when it sees an expression like this:

    
    $x ** 2 + 3 * $x - 5

it will first compare `**` against `+` and decide that the former is tighter,
and thus `$x ** 2` should be put together into a small tree. Later, it
compares `+` against `*`, and decides to turn `3 * $x` into a small tree. It
goes on like this, eventually ending up with this tree structure:

    
    infix:<->
     +-- infix:<+>
          +-- infix:<**>
          |    +-- term:<$x>
          |    +-- term:<2>
          +-- infix:<*>
               +-- term:<3>
               +-- term:<$x>

Because leaf nodes are evaluated first and the root node last, this tree
structure determines the order of evaluation for the expression. The order
ends up being the same as if the expression had these parentheses:

    
    (($x ** 2) + (3 * $x)) - 5

Which, again, is what we’ve learned to expect.

## Associativity

Another factor also governs how these invisible parentheses are to be
distributed: operator _associativity_. It’s the concern of how the operator
combines with multiple copies of itself, or other sufficiently similar
operators on the same precedence level.

Some examples serve to explain the difference:

    
    $x = $y = $x;     # becomes $x = ($y = $z)
    $x / $y / $z;     # becomes ($x / $y) / $z

In both of these cases, we may look at the way the parentheses are doled out,
and say “well, of course”. Of course we must first assign to `$y` and only
then to `$x`. And of course we first divide by `$y` and only then by `$z`. So
operators naturally have different associativity.

The optable parser compares not just the precedence of two operators but also,
when needed, their associativity. And it puts the parentheses in the right
place, just as above.

## User-defined operators

Now we come back to Perl not being a yes-man, and working hard to give you the
appropriate tools for the job.

Perl 6 allows you to define operators. See [my post from last
year](http://perl6advent.wordpress.com/2011/12/22/day-22-operator-overloading-
revisited/) on the details of how. But it also allows you to specify
precedence and associativity of each new operator.

As you specify a new operator, a new Perl 6 parser is automatically
constructed for you behind the scenes, which contains your new operator. In
this sense, the optable parser is open and extensible. And Perl 6 gives you
exactly the same tools for talking about precedence and associativity as the
compiler itself uses internally.

Perl treats you like a grown-up, and expects you to make good decisions based
on a thorough understanding of the problem space. I like that.

