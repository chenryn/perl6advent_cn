## Day 08 – Array-based objects

by [raydiak][4]

With the advent of a fully-realized object system in Perl 6, complete with formal attributes and accessors, hash-based objects are no longer the de-facto standard. Indeed, the underlying representation for the vast majority of classes (including Arrays and Hashes) is something called “P6Opaque”. This is because such complexities have been moved into the guts of the implementation, which provides a consistent interface to various internal data types transparently. Today’s post isn’t about underlying representations, though. The whole point is for us to be able to take advantage of the new arrangement by spending our time worrying about practical intentions instead of data type semantics.

So, what _are_ we talking about, and if nearly everything is just “opaque”, what makes an array look and act like an array? Arrays (and hashes too) are in many ways just another class. Specifically, the array class is named “Array” with a capital A. We can subclass it, add our own methods and properties, and it will still behave as any array, because it still is one. Many language elements which used to be a largely static part of Perl syntax have been reimplemented as first-class citizens such as grammars and roles. Creating an array-based class truly is as simple as:

class Vector is Array \{\}

## Binding and assignment

It doesn’t look like much yet, but we get a lot for that short bit of code. As might be expected from a Perl array, Vector is an auto-sizing sequence of writable scalars which are indexed by sequential integers. Our Vector class inherits Array’s constructor, which takes positional arguments. It does the Positional role, too, so it is followed by square brackets for subscripting and can be bound to containers declared with the “@” sigil, like so:

my @vec := Vector.new(1, 2, 3);

Note the “:=” binding instead of “=” assignment. Without the colon, a positional container will be created as an empty Array whose contained values are then set to the list after the “=”. In other words:

my @vec = Vector.new(1, 2, 3); # WRONG: assignment instead of binding
say @vec.WHAT; # (Array) instead of (Vector)

because it is the same as:

my @vec := Array.new;
@vec[] = Vector.new(1, 2, 3);

which isn’t what we want, of course. Since “$” means “any type” in Perl 6, as opposed to “a single value” as in Perl 5, we can also use scalar containers for our array-based objects, like any other object. No consideration of binding versus assignment is necessary in this case:

my $vec = Vector.new(1, 2, 3);
say $vec.WHAT; # (Vector)

## Methods

Now we know how to create and store our array-based objects in a couple of ways. But our class doesn’t actually do anything useful, so we add some methods:

class Vector is Array \{
    method magnitude () \{
        sqrt [+] self »\*\*» 2 
    \}

    method subtract (@vec) \{
        self.new( self »-« @vec )
    \}
\}

We have a couple simple vector operations. The subtract method takes _any_ positional object as its argument, including Arrays and Vectors, and returns another Vector to allow method chaining:

my @position := Vector.new(1, 2);
my @destination = 4, 6;
my $distance = @position.subtract(@destination).magnitude;
    # $distance = 5

In practical reality we would of course do various sanity checks such as type and dimension comparisons. Needlessly complicating the example serves no purpose, though. This is working pretty well so far. For us, at least.

## TIMTOWTDI

Many programmers, however, dislike the idea of treating an object as an array or vice-versa, for various reasons. They would rather have their objects all look like opaque scalars, and access their values via ordinary-looking method calls instead of subscripts. We might not share this view (we are, after all, writing an Array-based class), but imposing that singular vision on all of our users would be decidedly un-Perlish. And we’re half way there. Our Vector can already be stored in a scalar, as discussed before:

my $vec = Vector.new(0, 1);
say $vec.magnitude; # 1

It’s not a bad facade, for an array. But let’s see if we can do better, so we don’t alienate our more traditional users. What about the values? A normal Perl 6 object would expose those via lvalue accessors, so let’s add a few of our own:

class Vector is Array \{
    method x () is rw \{ self[0] \}
    method y () is rw \{ self[1] \}
    method z () is rw \{ self[2] \}

    method magnitude () \{
        sqrt [+] self »\*\*» 2 
    \}

    method subtract (@vec) \{
        self.new( self »-« @vec )
    \}
\}

Here we’re simply defining lvalue accessors with “is rw”, which means their return value can be assigned to with “=” like normal variables instead of through arguments to the accessor:

my $vec = Vector.new(1, 2);
$vec.z = 3;
say $vec; # 1 2 3

## Customizing the Constructor

Only one step remains to complete our somewhat seamless illusion: honoring those names if they are passed to the constructor. To accomplish this, we’ll write our own constructor to turn named arguments into positional ones, and pass them on to Array’s constructor implementation positionally:

class Vector is Array \{
    method new (\*@values is copy, \*%named) \{
        @values[0] = %named&lt;x&gt; if %named&lt;x&gt; :exists;
        @values[1] = %named&lt;y&gt; if %named&lt;y&gt; :exists;
        @values[2] = %named&lt;z&gt; if %named&lt;z&gt; :exists;

        nextwith(|@values);
    \}

    method x () is rw \{ self[0] \}
    method y () is rw \{ self[1] \}
    method z () is rw \{ self[2] \}

    method magnitude () \{
        sqrt [+] self »\*\*» 2 
    \}

    method subtract (@vec) \{
        self.new( self »-« @vec )
    \}
\}

Don’t forget to declare any parameters which you make changes to as “is copy”, as in the constructor above. Otherwise you run the risk of causing unintended changes to your users’ variables or having your routine just plain die when it tries to perform the assignment.

## Seeing is Believing

With the final piece in place, we can now treat our Vector class as a “normal” class with named properties:

my $vec = Vector.new(:x(1), :y(2));
$vec.z = 3;

as an array:

my @vec := Vector.new(1, 2);
@vec.push(3);

or even a mixture of the two, if you just plain want to do it how you feel like at any given moment, and don’t care _what_ anyone else thinks:

my $vec = Vector.new(:y(3), 0);
$vec.x++;
$vec[1]--;
$vec.z = 3;
.say for @$vec;
    # 1
    # 2
    # 3

## Closing Remarks

That concludes our demonstration for today, but our Vector class is still far from complete. If you’re looking for something to sharpen your Perl 6 teeth on, you could add methods for more of the basic vector operations, and generally experiment with your working model. Optimize methods with internal caching in private attributes. Export a convenience sub for construction (something like vector(1, 2, 3) instead of Vector.new(1, 2, 3)). Or maybe you want x, y, and z to be actual attributes with all of the extra semantics and meta goodness thereof, in which case you would probably do something in your constructor along the lines of binding the attributes to the array slots, or vice-versa. Or try something different based on a hash. Go wild. -Ofun, as the mantra goes.

Here’s hoping that on day 8 (a number thought by some to variously represent building, power, balance, and new beginnings), you’ve received the gift of inspiration, if nothing else, to look long and hard at all the new ways Perl 6 allows you to bend and blend traditionally rigid design patterns along with more specialized approaches. We have illustrated in our explorations that this power, as with any, can create ugliness and danger if not exercised with due care. It has also been made apparent, however, that wise application of this level of flexibility can sometimes better suit the practical goals, personal thinking style, and human nature of yourself and/or users of your code, and can be accomplished without introducing unreasonable complexity.

For a complete implementation of vectors in Perl 6, including overloaded operators for extra-sugary, very math-looking expressions, see [Math::Vector][5], one of a growing number of modules listed on [modules.perl6.org][6] and easily installed via [panda][7].


![][34]

  [4]: https://perl6advent.wordpress.com/author/raydiak0/ "View all posts by raydiak"
  [5]: https://github.com/colomon/Math-Vector
  [6]: http://modules.perl6.org/
  [7]: https://github.com/tadzik/panda
