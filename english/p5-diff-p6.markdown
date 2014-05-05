<>
* [NAME][1]
* [DESCRIPTION][2]
* [Bits and Pieces][3]
  * [Sigils][4]
  * [Hash elements no longer auto-quote][5]
  * [Global variables have a twigil][6]
  * [Command-line arguments][7]
  * [New ways of referring to array and hash elements][8]
  * [The double-underscore keywords are gone][9]
  * [Context][10]
* [Operators][11]
  * [qw() changes; new interpolating form][12]
  * [Other important operator changes][13]
* [Blocks and Statements][14]
  * [You don't need parens on control structure conditions][15]
  * [eval \{\} is now try \{\}][16]
  * [foreach becomes for][17]
  * [for becomes loop][18]
* [Regexes and Rules][19]
  * [New regex syntax][20]
  * [Anonymous regexpes are now default][21]
* [Subroutines][22]
* [Formats][23]
* [Packages][24]
* [Modules][25]
* [Objects][26]
  * [Method invocation changes from -&gt; to .][27]
  * [Dynamic method calls distinguish symbolic refs from hard refs][28]
  * [Built-in functions are now methods][29]
* [Overloading][30]
  * [Offering Hash and List semantics][31]
  * [Chaining file test operators has changed][32]
* [Builtin Functions][33]
  * [References are gone (or: everything is a reference)][34]
  * [say()][35]
  * [wantarray() is gone][36]
* [AUTHORS][37]

# [NAME][38]

Perl6::Perl5::Differences -- Differences between Perl 5 and Perl 6

# [DESCRIPTION][39]

This document is intended to be used by Perl 5 programmers who are new to Perl 6 and just want a quick overview of the main differences. More detail on everything can be found in the language reference, which have been linked to throughout. In certain cases, you can also just use Perl 5 code in Perl 6 and compiler may say what's wrong. Note that it cannot recognize every difference, as sometimes old syntax actually means something else in Perl 6.

This list is currently known to be incomplete.

# [Bits and Pieces][40]

## [Sigils][41]

Where you used to say:

    my @fruits = ("apple", "pear", "banana");
    print $fruit[0], "\\n";

You would now say:

    my @fruits = "apple", "pear", "banana";
    say @fruit[0];

Or even use the `<>` operator, which replaces `qw()`:

    my @fruits = &lt;apple pear banana&gt;;

Note that the sigil for fetching a single element has changed from `$` to `@`; perhaps a better way to think of it is that the sigil of a variable is now a part of its name, so it never changes in subscripting. This also applies to hashes.

For details, see ["Names and Variables" in S02][42].

## [Hash elements no longer auto-quote][43]

Hash elements no longer auto-quote:

    Was:    $days\{February\}
    Now:    %days\{'February'\}
    Or:     %days&lt;February&gt;
    Or:     %days&lt;&lt;February&gt;&gt;

The curly-bracket forms still work, but curly-brackets are more distinctly block-related now, so in fact what you've got there is a block that returns the value "February". The `<>` and `<<>>` forms are in fact just quoting mechanisms being used as subscripts (see below).

## [Global variables have a twigil][44]

Yes, a twigil. It's the second character in the variable name. For globals, it's a `*`

    Was:    $ENV\{FOO\}
    Now:    %\*ENV&lt;FOO&gt;

For details, see ["Names and Variables" in S02][45].

## [Command-line arguments][46]

The command-line arguments are now in `@*ARGS`, not `@ARGV`. Note the `*` twigil because `@*ARGS` is a global.

## [New ways of referring to array and hash elements][47]

Number of elements in an array:

    Was:    $#array+1 or scalar(@array)
    Now:    @array.elems

Index of last element in an array:

    Was:    $#array
    Now:    @array.end

Therefore, last element in an array:

    Was:    $array[$#array]
    Now:    @array[@array.end]
            @array[\*-1]              # beware of the "whatever"-star

For details, see ["Built-In Data Types" in S02][48]

## [The double-underscore keywords are gone][49]

    Old                 New
    ---                 ---
    \_\_LINE\_\_            $?LINE
    \_\_FILE\_\_            $?FILE
    \_\_PACKAGE\_\_         $?PACKAGE
    \_\_END\_\_             =begin END
    \_\_DATA\_\_            =begin DATA

See ["double-underscore forms are going away" in S02][50] for details. The `?` twigil refers to data that is known at compile time.

## [Context][51]

There are still three main contexts, void, item (formerly scalar) and list. Aditionally there are more specialized contexts, and operators that force that context.

    my @array = 1, 2, 3;

    # generic item context
    my $a = @array; say $a.WHAT;    # prints Array

    # string context
    say ~@array;                    # "1 2 3"

    # numeric context
    say +@array;                    # 3

    # boolean context
    my $is-nonempty = ?@array;

Apostrophes `'` and dashes `-` are allowed as part of identifiers, as long as they appear between two letters.

# [Operators][52]

A comprehensive list of operator changes is documented at ["Changes to Perl 5 operators" in S03][53] and ["New operators" in S03][54].

Some highlights:

## [`qw()` changes; new interpolating form][55]

    Was:    qw(foo)
    Now:    &lt;foo&gt;

    Was:    split ' ', "foo $bar bat"
    Now:    &lt;&lt;foo $bar bat&gt;&gt;

Quoting operators now have modifiers that can be used with them (much like regexes and substitutions in Perl 5), and you can even define your own quoting operators. See [S03][56] for details.

Note that `()` as a subscript is now a sub call, so instead of `qw(a b)` you would write `qw<a b>` or `qw[a b]` (if you don't like plain `<a b>`), that is).

## [Other important operator changes][57]

String concatenation is now done with `~`.

Regex match is done with the smart match operator `~~`, the perl 5 match operator `=~` is gone.

    if "abc" ~~ m/a/ \{ ... \}

`|` and `&` as infix operators now construct junctions. The binary AND and binary OR operators are split into string and numeric operators, that is `~&` is binary string AND, `+&` is binary numeric AND, `~|` is binary string OR etc.

    Was: $foo &amp; 1;
    Now: $foo +&amp; 1;

The bitwise operators are now prefixed with a +, ~ or ? depending if the data type is a number, string or boolean.

    Was: $foo &lt;&lt; 42;
    Now: $foo +&lt; 42;

The assignment operators have been changed in a similar vein:

    Was: $foo &lt;&lt;= 42;
    Now: $foo +&lt;= 42;

Parenthesis don't construct lists, they merely group. Lists are constructed with the comma operator. It has tighter precedence than the list assignment operator, which allows you to write lists on the right hand side without parens:

    my @list = 1, 2, 3;     # @list really has three elements

The arrow operator `->` for dereferencing is gone. Since everything is an object, and derferencing parenthesis are just method calls with syntactic sugar, you can directly use the appropriate pair of parentheses for either indexing or method calls:

    my $aoa = [[1, 2, 3], [4, 5, 6], [7, 8, 9]];
    say $aoa[1]\[0];         # 4

    my $s = sub \{ say "hi" \};
    $s();
    # or
    $s.();
    $lol.[1]\[0]

# [Blocks and Statements][58]

See [S04][59] for the full specification of blocks and statements in Perl6.

## [You don't need parens on control structure conditions][60]

    Was:    if ($a &lt; $b) \{ ... \}
    Now:    if  $a &lt; $b  \{ ... \}

Likewise for `while`, `for`, etc. If you insist on using parens, make sure there's a space after the `if`, otherwise it's a sub call.

## [eval \{\} is now try \{\}][61]

Using `eval` on a block is now replaced with `try`.

    Was:  eval \{
            # ...
          \};
          if ($@) \{
            warn "oops: $@";
          \}
    Now:  try  \{
             # ...
             CATCH \{ warn "oops: $!" \}
          \}

CATCH provides more flexiblity in handling errors. See ["Exception\_handlers" in S04][62] for details.

## [foreach becomes for][63]

    Was:    foreach (@whatever) \{ ... \}
    Now:    for @whatever       \{ ... \}

Also, the way of assigning to something other than `$_` has changed:

    Was:    foreach my $x (@whatever) \{ ... \}
    Now:    for @whatever -&gt; $x       \{ ... \}

This can be extended to take more than one element at a time:

    Was:    while (my($age, $sex, $location) = splice @whatever, 0, 3) \{ ... \}
    Now:    for @whatever -&gt; $age, $sex, $location \{ ... \}

(Except the `for` version does not destroy the array.)

See ["The for statement" in S04][64] and ["each" in S29][65] for details.

## [for becomes loop][66]

    Was:    for  ($i=0; $i&lt;10; $i++) \{ ... \}
    Now:    loop ($i=0; $i&lt;10; $i++) \{ ... \}

`loop` can also be used for infinite loops:

    Was:    while (1) \{ ... \}
    Now:    loop \{ ... \}

# [Regexes and Rules][67]

## [New regex syntax][68]

Here's a simple translation of a Perl5 regular expression to Perl6:

    Was:    $str =~ m/^\\d\{2,5\}\\s/i
    Now:    $str ~~ m:P5:i/^\\d\{2,5\}\\s/

The `:P5` modifier is there because the standard Perl6 syntax is rather different, and 'P5' notes a Perl5 compatibility syntax. For a substitution:

    Was:    $str =~ s/(a)/$1/e;
    Now:    $str ~~ s:P5/(a)/\{$0\}/;

Notice that `$1` starts at `$0` now, and `/e` is gone in favor of the embedded closure notation.

## [Anonymous regexpes are now default][69]

Anonymous regexpes are now default, unless used in boolean context.

    Was:    my @regexpes = (
                qr/abc/,
                qr/def/,
            );
    Now:    my @regexpes = (
                /abc/,
                /def/,
            );

Also, if you still want to mark regexp as anonymous, the `qr//` operator is now called `rx//` (Mnemonic: **r**ege**x**) or `regex { }`.

For the full specification, see [S05][70]. See also:

The related Apocalypse, which justifies the changes:

  http://dev.perl.org/perl6/doc/design/apo/A05.html

And the related Exegesis, which explains it more detail:

  http://dev.perl.org/perl6/doc/design/exe/E05.html

# [Subroutines][71]

# [Formats][72]

Formats will be handled by external libraries.

# [Packages][73]

# [Modules][74]

# [Objects][75]

Perl 6 has a "real" object system, with key words for classes, methods and attributes. Public attributes have the `.` twigil, private ones the `!` twigil.

    class YourClass \{
        has $!private;
        has @.public;

        # and with write accessor
        has $.stuff is rw;

        method do\_something \{
            if self.can('bark') \{
                say "Something doggy";
            \}
        \}
    \}

## [Method invocation changes from -&gt; to .][76]

    Was:    $object-&gt;method
    Now:    $object.method

## [Dynamic method calls distinguish symbolic refs from hard refs][77]

  Was: $self-&gt;$method()
  Now: $self.$method()      # hard ref
  Now: $self."$method"()    # symbolic ref

## [Built-in functions are now methods][78]

Most built-in functions are now methods of built-in classes such as `String`, `Array`, etc.

    Was:    my $len = length($string);
    Now:    my $len = $string.chars;

    Was:    print sort(@array);
    Now:    print @array.sort;
            @array.sort.print;

You can still say `sort(@array)` if you prefer the non-OO idiom.

# [Overloading][79]

Since both builtin functions and operators are multi subs and methods, changing their behaviour for particular types is a simple as adding the appropriate multi subs and methods. If you want these to be globally available, you have to put them into the `GLOBAL` namespace:

    multi sub GLOBAL::uc(TurkishStr $str) \{ ... \}

    # "overload" the string concatenation:
    multi sub infix:&lt;~&gt;(TurkishStr $us, TurkishStr $them) \{ ... \}

If you want to offer a type cast to a particular type, just provide a method with the same name as the type you want to cast to.

    sub needs\_bar(Bar $x) \{ ... \}
    class Foo \{
        ...
        # coercion to type Bar:
        method Bar \{ ... \}
    \}

    needs\_bar(Foo.new);         # coerces to Bar

## [Offering Hash and List semantics][80]

If you want to write a class whose objects can be assigned to a variable with the `@` sigil, you have to implement the `Positional` roles. Likewise, for the `%` sigil you need to do the `Associative` role. The `&` sigil implies `Callable`.

The roles provides the operators `postcircumfix:<[ ]>` (Positional; for array indexing), `postcircumfix:<{ }>` (Associative) and `postcircumfix:<()>` (Callable). The are technically just methods with a fancy syntax. You should override these to provide meaningful semantics.

    class OrderedHash does Associative \{
        multi method postcircumfix:&lt;\{ \}&gt;(Int $index) \{
            # code for accessing single hash elements here
        \}
        multi method postcircumfix:&lt;\{ \}&gt;(\*\*@slice) \{
            # code for accessing hash slices here
        \}
        ...
    \}

    my %orderedHash = OrderedHash.new();
    say %orderedHash\{'a'\};

See [S13][81] for all the gory details.

## [Chaining file test operators has changed][82]

    Was: if (-r $file &amp;&amp; -x \_) \{...\}
    Now: if $file ~~ :r &amp; :x  \{...\}

For details, see ["Changes to Perl 5 operators"/"The filetest operators now return a result that is both a boolean" in S03][83]

# [Builtin Functions][84]

A number of builtins have been removed. For details, see:

["Obsolete Functions" in S29][85]

## [References are gone (or: everything is a reference)][86]

`Capture` objects fill the ecological niche of references in Perl 6. You can think of them as "fat" references, that is, references that can capture not only the current identity of a single object, but also the relative identities of several related objects. Conversely, you can think of Perl 5 references as a degenerate form of `Capture` when you want to refer only to a single item.

  Was: ref $foo eq 'HASH'
  Now: $foo ~~ Hash

  Was: @new = (ref $old eq 'ARRAY' ) ? @$old : ($old);
  Now: @new = @$old;

  Was: %h = ( k =&gt; \\@a );
  Now: %h = ( k =&gt; @a );

To pass an argument to modify by reference:

  Was: sub foo \{...\};        foo(\\$bar)
  Now: sub foo ($bar is rw); foo($bar)

The "obsolete" reference above has the details. Also, look for _Capture_ under ["Names\_and\_Variables" in S02][87], or at the Capture FAQ, [Perl6::FAQ::Capture][88].

## [say()][89]

This is a version of `print` that auto-appends a newline:

    Was:    print "Hello, world!\\n";
    Now:    say   "Hello, world!";

Since you want to do that so often anyway, it seemed like a handy thing to make part of the language. This change was backported to Perl 5, so you can use `say` after you will `use v5.10` or better.

## [wantarray() is gone][90]

`wantarray` is gone. In Perl 6, context flows outwards, which means that a routine does not know which context it is in.

Instead you should return objects that do the right thing in every context.

# [AUTHORS][91]

Kirrily "Skud" Robert, `<skud@cpan.org>`, Mark Stosberg, Moritz Lenz, Trey Harris, Andy Lester

  [1]: #NAME
  [2]: #DESCRIPTION
  [3]: #Bits_and_Pieces
  [4]: #Sigils
  [5]: #Hash_elements_no_longer_auto-quote
  [6]: #Global_variables_have_a_twigil
  [7]: #Command-line_arguments
  [8]: #New_ways_of_referring_to_array_and_hash_elements
  [9]: #The_double-underscore_keywords_are_gone
  [10]: #Context
  [11]: #Operators
  [12]: #qw()_changes%3B_new_interpolating_form
  [13]: #Other_important_operator_changes
  [14]: #Blocks_and_Statements
  [15]: #You_don%27t_need_parens_on_control_structure_conditions
  [16]: #eval_%7B%7D_is_now_try_%7B%7D
  [17]: #foreach_becomes_for
  [18]: #for_becomes_loop
  [19]: #Regexes_and_Rules
  [20]: #New_regex_syntax
  [21]: #Anonymous_regexpes_are_now_default
  [22]: #Subroutines
  [23]: #Formats
  [24]: #Packages
  [25]: #Modules
  [26]: #Objects
  [27]: #Method_invocation_changes_from_-%3E_to_.
  [28]: #Dynamic_method_calls_distinguish_symbolic_refs_from_hard_refs
  [29]: #Built-in_functions_are_now_methods
  [30]: #Overloading
  [31]: #Offering_Hash_and_List_semantics
  [32]: #Chaining_file_test_operators_has_changed
  [33]: #Builtin_Functions
  [34]: #References_are_gone_(or%3A_everything_is_a_reference)
  [35]: #say()
  [36]: #wantarray()_is_gone
  [37]: #AUTHORS
  [38]: #___top "click to go to top of document"
  [39]: #___top "click to go to top of document"
  [40]: #___top "click to go to top of document"
  [41]: #___top "click to go to top of document"
  [42]: http://feather.perl6.nl/syn/S02.html#Names_and_Variables
  [43]: #___top "click to go to top of document"
  [44]: #___top "click to go to top of document"
  [45]: http://feather.perl6.nl/syn/S02.html#Names_and_Variables
  [46]: #___top "click to go to top of document"
  [47]: #___top "click to go to top of document"
  [48]: http://feather.perl6.nl/syn/S02.html#Built-In_Data_Types
  [49]: #___top "click to go to top of document"
  [50]: http://feather.perl6.nl/syn/S02.html#double-underscore_forms_are_going_away
  [51]: #___top "click to go to top of document"
  [52]: #___top "click to go to top of document"
  [53]: http://feather.perl6.nl/syn/S03.html#Changes_to_Perl_5_operators
  [54]: http://feather.perl6.nl/syn/S03.html#New_operators
  [55]: #___top "click to go to top of document"
  [56]: http://feather.perl6.nl/syn/S03.html
  [57]: #___top "click to go to top of document"
  [58]: #___top "click to go to top of document"
  [59]: http://feather.perl6.nl/syn/S04.html
  [60]: #___top "click to go to top of document"
  [61]: #___top "click to go to top of document"
  [62]: http://feather.perl6.nl/syn/S04.html#Exception_handlers
  [63]: #___top "click to go to top of document"
  [64]: http://feather.perl6.nl/syn/S04.html#The_for_statement
  [65]: http://feather.perl6.nl/syn/S29.html#each
  [66]: #___top "click to go to top of document"
  [67]: #___top "click to go to top of document"
  [68]: #___top "click to go to top of document"
  [69]: #___top "click to go to top of document"
  [70]: http://feather.perl6.nl/syn/S05.html
  [71]: #___top "click to go to top of document"
  [72]: #___top "click to go to top of document"
  [73]: #___top "click to go to top of document"
  [74]: #___top "click to go to top of document"
  [75]: #___top "click to go to top of document"
  [76]: #___top "click to go to top of document"
  [77]: #___top "click to go to top of document"
  [78]: #___top "click to go to top of document"
  [79]: #___top "click to go to top of document"
  [80]: #___top "click to go to top of document"
  [81]: http://feather.perl6.nl/syn/S13.html
  [82]: #___top "click to go to top of document"
  [83]: http://feather.perl6.nl/syn/S03.html#Changes_to_Perl_5_operators%22%2F%22The_filetest_operators_now_return_a_result_that_is_both_a_boolean
  [84]: #___top "click to go to top of document"
  [85]: http://feather.perl6.nl/syn/S29.html#Obsolete_Functions
  [86]: #___top "click to go to top of document"
  [87]: http://feather.perl6.nl/syn/S02.html#Names_and_Variables
  [88]: http://feather.perl6.nl/syn/Perl6%3A%3AFAQ%3A%3ACapture.html
  [89]: #___top "click to go to top of document"
  [90]: #___top "click to go to top of document"
  [91]: #___top "click to go to top of document"