# [Perl 6 Advent Calendar][1]

Something cool about Perl 6 every day

----

« [Day 22 – A catalogue of operator types][2][Day 24 – Advent Ventures][3] »

## Day 23 – Unary Sort

by [Moritz][4]

Most languages or libraries that provide a generic sort routine allow you to specify a comparator, that is a callback that tells the sort routine how two given elements compare. Perl is no exception.

For example in Perl 5, which defaults to lexicographic ordering, you can request numeric sorting like this:

     use v5;
     my @sorted = sort { $a <=> $b } @values;

Perl 6 offers a similar option:

     use v6;
     my @sorted = sort { $^a <=> $^b }, @values;

The main difference is that the arguments are not passed through the global variables `$a` and `$b`, but rather as arguments to the comparator. The comparator can be anything callable, that is a named or anonymous sub or a block. The `{ $^a <=> $^b}` syntax is not special to sort, I have just used [placeholder variables][5] to show the similarity with Perl 5. Other ways to write the same thing are:

     my @sorted = sort -> $a, $b { $a <=> $b }, @values;
     my @sorted = sort * <=> *, @values;
     my @sorted = sort &infix:«<=>», @values;

The first one is just another syntax for writing blocks, `* <=> *` use [\* to automatically curry an argument][6], and the final one directly refers to the routine that implements the `<=>` "space ship" operator (which does numeric comparison).

But Perl strives not only to make hard things possible, but also to make simple things easy. Which is why Perl 6 offers more convenience. Looking at sorting code, one can often find that the comparator duplicates code. Here are two common examples:

     # sort words by a sort order defined in a hash:
     my %rank = a => 5, b => 2, c => 10, d => 3;
     say sort { %rank{$^a} <=> %rank{$^b} }, 'a'..'d';
     #          ^^^^^^^^^^     ^^^^^^^^^^  code duplication
    
     # sort case-insensitively
     say sort { $^a.lc cmp $^b.lc }, @words;
     #          ^^^^^^     ^^^^^^  code duplication

Since we love convenience and hate code duplication, Perl 6 offers a shorter solution:

     # sort words by a sort order defined in a hash:
     say sort { %rank{$_} }, 'a'..'d';
    
     # sort case-insensitively
     say sort { .lc }, @words;

`sort` is smart enough to recognize that the code object code now only takes a single argument, and now uses it to map each element of the input list to new values, which it then sorts with normal `cmp` sort semantics. But it returns the original list in the new order, not the transformed elements. This is similar to the [Schwartzian Transform][7], but very convenient since it's built in.

So the code block now acts as a transformer, not a comparator.

Note that in Perl 6, `cmp` is smart enough to compare strings with string semantics and numbers with number semantics, so producing numbers in the transformation code generally does what you want. This implies that if you want to sort numerically, you can do that by forcing the elements into numeric context:

     my @sorted-numerically = sort +*, @list;

And if you want to sort in reverse numeric order, simply use `-*` instead.

The unary sort is very convenient, so you might wonder why the Perl 5 folks haven't adopted it yet. The answer is that since the sort routine needs to find out whether the callback takes one or two arguments, it relies on subroutine (or block) signatures, something not (yet?) present in Perl 5. Moreover the "smart" `cmp` operator, which compares number numerically and strings lexicographically, requires a type system which Perl 5 doesn't have.

I strongly encourage you to try it out. But be warned: Once you get used to it, you'll miss it whenever you work in a language or with a library that lacks this feature.

![][48]

  [4]: https://perl6advent.wordpress.com/author/foobar123/ "View all posts by Moritz"
  [5]: http://perlcabal.org/syn/S06.html#Placeholder_variables
  [6]: http://perlgeek.de/blog-en/perl-5-to-6/28-currying.html
  [7]: https://en.wikipedia.org/wiki/Schwartzian_transform
