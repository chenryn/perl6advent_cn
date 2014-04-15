Over the years, I've written many variations on this code:

    my %words;
    for slurp.comb(/\w+/).map(*.lc) -> $word {
        %words{$word}++;
    }

(Aside: `slurp.comb(/\w+/).map(*.lc)` does the standard Perl trick of reading files specified on the command line or standard in, goes through the data for words, and makes them lowercase.)

Perl 6 introduces two new Associative types for dealing with this sort of functionality. `KeyBag` is drop-in replacement for `Hash` in this sort of case:

    my %words := KeyBag.new;
    for slurp.comb(/\w+/).map(*.lc) -> $word {
        %words{$word}++;
    }

Why would you prefer `KeyBag` over `Hash` in this case, considering that it's a bit more code? Well, it does a better job of saying what you mean, if what you want is a positive `Int`-valued `Hash`. It actually enforces this as well:

    > %words{"the"} = "green";
    Unhandled exception: Cannot parse number: green

That's Niecza's error; Rakudo's is less clear, but the important point is you get an error; Perl 6 detects that you've violated your contract and complains.

And `KeyBag` has a couple more tricks up its sleeve. First, four lines to initialize your `KeyBag` isn't terribly verbose, but Perl 6 has no trouble getting it down to one line:

    my %words := KeyBag.new(slurp.comb(/\w+/).map(*.lc));

`KeyBag.new` does its best to turn whatever it is given into the contents of a `KeyBag`. Given a `List`, each of the elements is added to the `KeyBag`, with the exact same result of our earlier block of code.

If you don't need to modify the bag after its creation, then you can use `Bag` instead of `KeyBag`. The difference is `Bag` is immutable; if `%words` is a `Bag`, then `%words{$word}++` is illegal. If immutability is okay for your application, then you can make the code even more compact:

    my %words := bag slurp.comb(/\w+/).map(*.lc);

`bag` is a helper sub that just calls `Bag.new` on whatever you give it. (I'm not sure why there is no equivalent `keybag` sub.)

`Bag` and `KeyBag` have a couple more tricks up their sleeve. They have their own versions of `.roll` and `.pick` which weigh their results according to the given values:

    > my $bag = bag "red" => 2, "blue" => 10;
    > say $bag.roll(10);
    > say $bag.pick(*).join(" ");
    blue blue blue blue blue blue red blue red blue
    blue red blue blue red blue blue blue blue blue blue blue

This wouldn't be too hard to emulate using a normal `Array`, but this version would be:

    > $bag = bag "red" => 20000000000000000001, "blue" => 100000000000000000000;
    > say $bag.roll(10);
    > say $bag.pick(10).join(" ");
    blue blue blue blue red blue red blue blue blue
    blue blue blue red blue blue blue red blue blue

They also work with all the standard `Set` operators, and have a few of their own as well. Here's a simple demonstration:

    sub MAIN($file1, $file2) {
        my $words1 = bag slurp($file1).comb(/\w+/).map(*.lc);
        my $words2 = set slurp($file2).comb(/\w+/).map(*.lc);
        my $unique = ($words1 (-) $words2);
        for $unique.list.sort({ -$words1{$_} })[^10] -> $word {
            say "$word: { $words1{$word} }";
        }
    }

Passed two filenames, this makes a `Bag` from the words in the first file, a `Set` from the words in the second file, uses the set difference operator `(-)` to compute the set of words which are only in the first file, sorts those words by their frequency of appearance, and then prints out the top ten.

This is the perfect point to introduce `Set`. As you might guess from the above, it works much like `Bag`. Where `Bag` is a `Hash` from `Any` to positive `Int`, `Set` is a `Hash` from `Any` to `Bool::True`. `Set` is immutable, and there is also a mutable `KeySet`.

Between `Set` and `Bag` we have a very rich collection of operators:

<table align="center" border="1" cellpadding="0" cellspacing="0" summary="Set &amp; Bag operators">
<tbody>
<tr>
<td align="center">Operation</td>
<td align="center">Unicode</td>
<td align="center">“Texas”</td>
<td align="center">Result Type</td>
</tr>
<tr>
<td align="center">is an element of</td>
<td align="center">∈</td>
<td align="center">(elem)</td>
<td align="center">Bool</td>
</tr>
<tr>
<td align="center">is not an element of</td>
<td align="center">∉</td>
<td align="center">!(elem)</td>
<td align="center">Bool</td>
</tr>
<tr>
<td align="center">contains</td>
<td align="center">∋</td>
<td align="center">(cont)</td>
<td align="center">Bool</td>
</tr>
<tr>
<td align="center">does not contain</td>
<td align="center">∌</td>
<td align="center">!(cont)</td>
<td align="center">Bool</td>
</tr>
<tr>
<td align="center">union</td>
<td align="center">∪</td>
<td align="center">(|)</td>
<td align="center">Set or Bag</td>
</tr>
<tr>
<td align="center">intersection</td>
<td align="center">∩</td>
<td align="center">(&amp;)</td>
<td align="center">Set or Bag</td>
</tr>
<tr>
<td align="center">set difference</td>
<td align="center"></td>
<td align="center">(-)</td>
<td align="center">Set</td>
</tr>
<tr>
<td align="center">set symmetric difference</td>
<td align="center"></td>
<td align="center">(^)</td>
<td align="center">Set</td>
</tr>
<tr>
<td align="center">subset</td>
<td align="center">⊆</td>
<td align="center">(&lt;=)</td>
<td align="center">Bool</td>
</tr>
<tr>
<td align="center">not a subset</td>
<td align="center">⊈</td>
<td align="center">!(&lt;=)</td>
<td align="center">Bool</td>
</tr>
<tr>
<td align="center">proper subset</td>
<td align="center">⊂</td>
<td align="center">(&lt;)</td>
<td align="center">Bool</td>
</tr>
<tr>
<td align="center">not a proper subset</td>
<td align="center">⊄</td>
<td align="center">!(&lt;)</td>
<td align="center">Bool</td>
</tr>
<tr>
<td align="center">superset</td>
<td align="center">⊇</td>
<td align="center">(&gt;=)</td>
<td align="center">Bool</td>
</tr>
<tr>
<td align="center">not a superset</td>
<td align="center">⊉</td>
<td align="center">!(&gt;=)</td>
<td align="center">Bool</td>
</tr>
<tr>
<td align="center">proper superset</td>
<td align="center">⊃</td>
<td align="center">(&gt;)</td>
<td align="center">Bool</td>
</tr>
<tr>
<td align="center">not a proper superset</td>
<td align="center">⊅</td>
<td align="center">!(&gt;)</td>
<td align="center">Bool</td>
</tr>
<tr>
<td align="center">bag multiplication</td>
<td align="center">⊍</td>
<td align="center">(.)</td>
<td align="center">Bag</td>
</tr>
<tr>
<td align="center">bag addition</td>
<td align="center">⊎</td>
<td align="center">(+)</td>
<td align="center">Bag</td>
</tr>
</tbody>
</table>

Most of these are self-explanatory. Operators that return `Set` promote their arguments to `Set` before doing the operation. Operators that return `Bag` promote their arguments to `Bag` before doing the operation. Operators that return `Set` or Bag promote their arguments to `Bag` if at least one of them is a `Bag` or `KeyBag`, and to `Set` otherwise; in either case they return the type promoted to.

Please note that while the set operators have been in Niecza for some time, they were only added to Rakudo yesterday, and only in the Texas variations.

A bit of a word may be needed for the different varieties of unions and intersections of `Bag`. The normal union operator takes the max of the quantities in either bag. The intersection operator takes the min of the quantities in either bag. Bag addition adds the quantities from either bag. Bag multiplication multiplies the quantities from either bag. (There is some question if the last operation is actually useful for anything — if you know of a use for it, please let us know!)

    > my $a = bag <a a a b b c>;
    > my $b = bag <a b b b>;
    
    > $a (|) $b;
    bag("a" => 3, "b" => 3, "c" => 1)
    
    > $a (&) $b;
    bag("a" => 1, "b" => 2)
    
    > $a (+) $b;
    bag("a" => 4, "b" => 5, "c" => 1)
    
    > $a (.) $b;
    bag("a" => 3, "b" => 6)

I've placed my full set of examples for this article and several data files to play with on [Github](https://github.com/colomon/perl6-set-bag-demo). All the sample files should work on the latest very latest Rakudo from Github; I think all but `most-common-unique.pl` and `bag-union-demo.pl` should work with the latest proper Rakudo releases. Meanwhile those two scripts will work on Niecza, and with any luck I'll have the bug stopping the rest of the scripts from working there fixed in the next few hours.

A quick example of getting the 10 most common words in Hamlet which are not found in Much Ado About Nothing:

    
    > perl6 bin/most-common-unique.pl data/Hamlet.txt data/Much_Ado_About_Nothing.txt
    ham: 358
    queen: 119
    hamlet: 118
    hor: 111
    pol: 86
    laer: 62
    oph: 58
    ros: 53
    horatio: 48
    clown: 47
    

