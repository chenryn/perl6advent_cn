## Day 12 – Slicing with adverbs, the only way!

by [liztormato][4]

My involvement with adverbs in Perl 6 began very innocently. I had the idea to creating a small, lightning talk size presentation about how the Perl 5 fat arrow corresponds to Perl 6’s fatarrow and adverbs. And how they relate to hash / array slices. And then had to find out you couldn’t combine them on hash / array slices. Nor could you pass values to them.

And so started my first bigger project on Rakudo Perl 6. Making adverbs work as specced on hashes and arrays, and on the way, expand the spec as well. So, do they now work? Well, all spectests pass. But while preparing this blog post, I happened to find [a bug][5] which is now waiting for my further attention. There’s always one more bug.

What are the adverbs you can use with hash and array slices?

<table>
<tr>
<th>name</th>
<th>description</th>
</tr>
<tr>
<td>:exists</td>
<td>whether element(s) exist(ed)</td>
</tr>
<tr>
<td>:delete</td>
<td>remove element(s), return value (if any)</td>
</tr>
<tr>
<td>:kv</td>
<td>return **key(s) and value(s)** as Parcel</td>
</tr>
<tr>
<td>:p</td>
<td>return **key(s) and value(s)** as Parcel of Pairs</td>
</tr>
<tr>
<td>:k</td>
<td>return **key(s) only**</td>
</tr>
<tr>
<td>:v</td>
<td>return **value(s) only**</td>
</tr>
</table>

## :exists

This adverb replaces the now deprecated _.exists_ method. Adverbs provide a generic interface to hashes and arrays, regardless of number of elements requested. The _.exists_ method only ever allowed checking for a single key.

Examples speak louder than words. To check whether a single key exists:

$ perl6 -e 'my %h = a=&gt;1, b=&gt;2; say %h&lt;a&gt;:exists’
True

If we expand this to a slice, we get a Parcel of boolean values:

$ perl6 -e 'my %h = a=&gt;1, b=&gt;2; say %h&lt;a b c&gt;:exists'
True True False

Note that if we ask for a single key, we get a boolean value back, not a Parcel with one Bool in it.

$ perl6 -e 'my %h = a=&gt;1, b=&gt;2; say (%h&lt;a&gt;:exists).WHAT’
(Bool)

If it is clear that we ask for multiple keys, or not clear at compile time that we are only checking for one key, we get back a Parcel:

$ perl6 -e 'my %h = a=&gt;1, b=&gt;2; say (%h&lt;a b c&gt;:exists).WHAT’
(Parcel)
$ perl6 -e 'my @a="a"; my %h = a=&gt;1, b=&gt;2; say (%h\{@a\}:exists).WHAT'
(Parcel)

Sometimes it is handier to know if something does **not** exist. You can easily do this by negating the adverb by prefixing it with **!**: they’re really just like named parameters anyway!

$ perl6 -e 'my %h = a=&gt;1, b=&gt;2; say %h&lt;c&gt;:!exists'
True

## :delete

This is the only adverb that actually can make changes to the hash or array it is (indirectly) applied to. It replaces the now deprecated _.delete_ method.

$ perl6 -e 'my %h = a=&gt;1, b=&gt;2; say %h&lt;a&gt;:delete; say %h.perl'
1
("b" =&gt; 2).hash

Of course, you can also delete slices:

$ perl6 -e 'my %h = a=&gt;1, b=&gt;2; say %h&lt;a b c&gt;:delete; say %h.perl'
1 2 (Any)
().hash

Note that the **(Any)** is the value returned for the non-existing key. If you happened to have given the hash a _default_ value, it would have looked like this:

$ perl6 -e 'my %h is default(42) = a=&gt;1, b=&gt;2; say %h&lt;a b c&gt;:delete; say %h.perl'
1 2 42
().hash

But the behaviour of the _is default_ maybe warrants a blog post of itself, so I won’t go into it now.

Like with _:exists_, you can negate the :delete adverb. But there wouldn’t be much point, as you might have well not specified it at all. However, since adverbs are basically just named parameters, you **can** make the :delete attribute conditional:

$ perl6 -e 'my $really = True; my %h = a=&gt;1, b=&gt;2; say %h&lt;a b c&gt;:delete($really); say %h.perl'
1 2 (Any)
().hash

Because the value passed to the adverb was true, the deletion actually took place. However, if we pass a false value:

$ perl6 -e ‘my $really; my %h = a=&gt;1, b=&gt;2; say %h&lt;a b c&gt;:delete($really); say %h.perl'
1 2 (Any)
("a" =&gt; 1, "b" =&gt; 2).hash

It doesn’t. Note that the return value did not change: the deletion was simply **not** performed. This can e.g. be very handy if you have a subroutine or method doing some kind of custom slice, and you want to have an optional parameter indicating whether the slice should be deleted as well: simply pass that parameter as the adverb’s value!

## :kv, :p, :k, :v

These 4 attributes modify the returned values from any hash / array slice. The **:kv** attribute returns a Parcel with keys and values interspersed. The **:p** attribute returns a Parcel of Pairs. The **:k** and **:v** attributes return the key only, or the value only.

$ perl6
&gt; my %h = a =&gt; 1, b =&gt; 2;
("a” =&gt; 1, "b” =&gt; 2).hash
&gt; %h&lt;a&gt;:kv
a 1
&gt; %h&lt;a&gt;:p
"a" =&gt; 1
&gt; %h&lt;a&gt;:k
a
&gt; %h&lt;a&gt;:v
1

Apart from modifying the return value, these attributes **also** act as a filter for existing keys only. Please note the difference in return values:

&gt; %h&lt;a b c&gt;
1 2 (Any)
&gt; %h&lt;a b c&gt;:v
1 2

Because the _:v_ attribute acts as a filter, there is no _(Any)_. But sometimes, you want to not have this behaviour. To achieve this, you can negate the attribute:

&gt; %h&lt;a b c&gt;:k
a b
&gt; %h&lt;a b c&gt;:!k
a b c

## Combining adverbs

You can also combine adverbs on hash / array slices. The most useful combinations are with one or two of _:exists_ and _:delete_, with zero or one of _:kv, :p, :k, :v_. Some examples, like putting a slice out of one hash into a new hash:

$ perl6 -e 'my %h = a=&gt;1, b=&gt;2; my %i = (%h&lt;a c&gt;:delete:p).list; say %h.perl; say %i.perl'
("b” =&gt; 2).hash
("a” =&gt; 1).hash

Or the keys that were actually deleted:

$ perl6 -e 'my %h = a=&gt;1, b=&gt;2; say %h&lt;a b c&gt;:delete:k’
a b

We actually [have a spec][6] that describes which combinations are valid, and what they should return.

## Arrays are not Hashes

Apart from hashes using \{\} for slices, and arrays [] for slices, the adverbial syntax for hash and array slices are the same. But there are some subtle differences. First of all, the “key” of an element in an array, is its **index**. So, to show the indexes of elements in an array that have a defined value, one can use the **:k** attribute:

$ perl6 -e 'my @a; @a[3] = 1; say @a[]:k'
3

Or, to create a Parcel with all elements in an array:

$ perl6 -e 'my @a; @a[3] = 1; say @a[]:!k’
0 1 2 3

However, deleting an element from an array, is similar to assigning **Nil** to it, so it will return its default value (usually (Any)):

$ perl6 -e 'my @a = ^10; @a[3]:delete; say @a[2,3,4]; say @a[2,3,4]:exists'
2 (Any) 4
True False True

If we have specified a default value for the array, the result is slightly different:

$ perl6 -e 'my @a is default(42) = ^10; @a[3]:delete; say @a[2,3,4]; say @a[2,3,4]:exists'
2 42 4
True False True

So, even though the element “does not exist”, it can return a defined value! As said earlier, that may become a blog post for another day!

## Conclusion

Slices with adverbs are a powerful way of handling your data structures, be they hashes or arrays. It will take a while to get used to all of the combinations of adverbs that can be specified. But once you’re used to them, they provide you with a concise way of dicing and slicing your data that would previously have involved more elaborate structures with loops and conditionals. Of course, if you want to, you can still do that: it’s not illegal to program Perl 5 in Perl 6 :-)


![][38]

  [4]: https://perl6advent.wordpress.com/author/liztormato/ "View all posts by liztormato"
  [5]: https://rt.perl.org/rt3//Public/Bug/Display.html?id=120739
  [6]: http://perlcabal.org/syn/S02.html#Combining_subscript_adverbs
