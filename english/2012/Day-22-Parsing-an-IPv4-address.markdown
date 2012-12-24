_Guest post by Herbert Breunung (lichtkind)._

Perl 5 brought regexes to mainstream programming and set a standard, one that
is felt as relevant even in Redmond. Perl 6, of course, steps up the game by
adding many new features to the regex camp, including [easy-to-build
grammars](http://perl6advent.wordpress.com/2009/12/21/day-21-grammars-and-
actions) for your own complex parsers. But without getting too complex, you
can get a lot of joy out of Perl 6′s `rx` (thats how Perl 6 spells Perl 5′s
`qr` operator,

that enables you to save a Regex in a variable).

Because the Perl 6 regex syntax is less littered with exceptional cases,

Larry Wall also likes to joke that he back the “regular” back into “regular
expression”.

Some of the changes are:

  * most special variables are gone,
  * non-capturing groups and other grouping syntax is easier to type,
  * no more single/multi line modes,
  * x mode became default, making whitespace non-significant by default.

In summary, regexes are more regular than in Perl 5, confirming Larry’s joke.
They try a bit harder to make your life easier when you need to match text.
Under the hood, regexes have blossomed out into a complete sub-language inside
of the bigger Perl 6 language. A language with its own parsing rules.

But don’t fret; not everything has changed. Some things remain the same:

    
    /\d+/

This regex still matches one or more consecutive digits.

Similarly, if you want to capture the digits, you can do this, just like
you’re used to:

    
    /(\d+)/

You’ll find the matched digits in `$0`, not `$1` as in Perl 5. All the special
variables `$0`, `$1`, `$2` are really syntactic sugar for indexing the _match
variable_ (`$/[0]`, `$/[1]`, `$/[2]`). Because indices start at 0, it makes
sense for the first matched group to be `$0`. In Perl 5, `$0` contains the
name of the script or program, but this has been renamed into
`$*EXECUTABLE_NAME` in Perl 6.

Should you be interested in getting all of the captured groups of a regex
match, you can use `@()`, which is syntactic sugar for `@($/)`.

The object in the `$/` variable holds lots of useful information about the
last match. For example, `$/.from` will give you the starting string position
of the match.

But `$0` will get us far enough for this post. We use it to extract individual
features from a string.

Sometimes we want to extract a whole bunch of similar things at once. Then we
can use the `:g` (or `:global`) modifier on the regex:

    
    $_ = '1 23 456 78.9';
    say .Str for m:g/(\d+)/; # 1 23 456 78 9

Note that the `:g` — as opposed to prior regex implementations &mash; sits up
front, right at the start of the regex. Not at the end. That way, when you
read the regex from left to right, you will know from the start how the regex
is doing its matching. No more end-heavy regex expressions.

Matching “all things that look like this” is so useful, that there’s even a
dedicated method for that, `.comb`:

    
    $str.comb(/\d+/);

If you’re familiar with `.split`, you can think of `.comb` as its cheerful
cousing, matching all the things that `.split` discards.

Let’s tackle the matching of an IPv4 address. Coming from a Perl 5 angle, we
expect to have to do something like this:

    
    /(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/

This won’t do in Perl 6, though. First of all, the `{}` blocks are real blocks
in a Perl 6 regex; they contain Perl 6 code. Second, because Perl 6 has lots
of error handling to catch p5isms, like this, you’ll get an error saying
“Unsupported use of {N,M} as general quantifier; in Perl 6 please use ** N..M
(or ** N..*)”.

So let’s do that. To match between one and three digits in a Perl 6 regex, we
should type:

    
    /\d ** 1..3/

Note how the regex sublanguage re-uses parts from the main Perl 6 language.
`**` can be seen as a kind of exponentiation (if we squint), in that we’re
taking `\d` “to the between-first-and-third power”. And the range notation
`1..3` exists both outside and within regexes.

Using our new knowledge about the repetition quantifier, we end up with
something like this:

    
    /(\d**1..3) \. (\d**1..3) \. (\d**1..3) \. (\d**1..3)/

Thats still kinda clunky. We might end up wishing that we could use the
repetition operator again, but those literal dots in between prevent us from
doing that. If only we could specify repetition a given number of times _and_
a divider.

In Perl 6 regexes, you can.

    
    / (\d ** 1..3) ** 4 % '.' /

The `%` operator here is a _quantifier modifier_, so it can only follow on a
quantifier like `*` or `+` or `**`. The choice of `%` for this function is
relatively new in Perl 6, and you may prefer to read it as “modulo”, just like
in the main language. That is, “match four groups of digits, modulo literal
dots in between”. Or you could think of the dots in between as the
“remainder”, the separators that are left after you’ve parsed the actual
elements.

Oh, and you might’ve noticed that `\.` changed to `'.'` on the way. We can use
either; they mean exactly the same. In Perl 5, there isn’t a simple rule
saying which symbols have a magic meaning and which ones simply signify
themselves. In Perl 6, it’s easy: word characters (alphanumerics and the
underscore) always signify themselves. Everything else has to be escaped or
quoted to get its literal meaning.

Putting it all together, here’s how we would extract IPv4 addresses out of a
string:

    
    $_ = "Go 127.0.0.1, I said! He went to 173.194.32.32.";
    
    say .Str for m:g/ (\d ** 1..3) ** 4 % '.' /;
    # output: 127.0.0.1 173.194.32.32

Or, we could use `.comb`:

    
    $_ = "Go 127.0.0.1, I said! He went to 173.194.32.32.";
    my @ip4addrs = .comb(/ (\d ** 1..3) ** 4 % '.' /);

If we’re interested in the individual integers, we can get those too:

    
    $_ = "Go 127.0.0.1, I said! He went to 173.194.32.32.";
    say .list>>.Str.perl for m:g/ (\d ** 1..3) ** 4 % '.' /;
    # output: ("127", "0", "0", "1") ("173", "194", "32", "32")

If you want to know more, read [the S05](http://perlcabal.org/syn/S05.html),
or watch me battling with my slide deck and the English language in [this
presentation about regexes](http://www.youtube.com/watch?v=6Q19mbOtk3c).

