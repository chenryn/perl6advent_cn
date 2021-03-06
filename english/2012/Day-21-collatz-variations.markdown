The [Collatz sequence](http://en.wikipedia.org/wiki/Collatz_conjecture) is one
of those interesting “simple” math problems that I’ve run into a number of
times. Most recently a blog post on [programming it in Racket](http://blog
.racket-lang.org/2012/10/the-3n1-problem_4990.html) showed up on Hacker News.
As happens so often, I instantly wanted to implement it in Perl 6.

    
    sub collatz-sequence(Int $start) { 
        $start, { when * %% 2 { $_ / 2 }; when * !%% 2 { 3 * $_ + 1 }; } ... 1;
    }
    
    sub MAIN(Int $min, Int $max) {
        say [max] ($min..$max).map({ +collatz-sequence($_) });        
    }
    

  
This is a very straightforward implementation of the Racket post’s `max-cycle-
length-range` as a stand-alone p6 script. `collatz-sequence` generates the
sequence using the p6 sequence operator. Start with the given number. If it is
divisible by two, do so: `when * %% 2 { $_ / 2 }`. If it is not, multiply by
three and add 1: `when * !%% 2 { 3 * $_ + 1 }`. Repeat this until the sequence
reaches 1.

`MAIN(Int $min, Int $max)` sets up our main function to take two integers.
Many times I don’t bother with argument types in p6, but this provides a nice
feedback for users:

    
    > perl6 collatz.pl blue red
    Usage:
      collatz.pl <min> <max> 
    

  
The core of it just maps the numbers from `$min` to `$max` (inclusive) to the
length of the sequence (`+collatz-sequence`) and then says the max of the
resulting list (`[max]`).

Personally I’m a big fan of using the sequence operator for tasks like this;
it directly represents the algorithm constructing the Collatz sequence in a
simple and elegant fashion. On the other hand, you should be able to memoize
the recursive version for a speed increase. Maybe that would give it an edge
over the sequence operator version?

Well, I was wildly wrong about that.

    
    sub collatz-length($start) {
        given $start {
            when 1       { 1 }
            when * !%% 2 { 1 + collatz-length(3 * $_ + 1) } 
            when * %% 2  { 1 + collatz-length($_ / 2) } 
        }
    }
    
    sub MAIN($min, $max) {
        say [max] ($min..$max).map({ collatz-length($_) });        
    }
    

  
This recursive version, which makes no attempt whatsoever to be efficient, is
actually better than twice as fast as the sequence operator version. In
retrospect, this makes perfect sense: I was worried about the recursive
version making a function call for every iteration, but the sequence version
has to make two, one to calculate the next iteration and the other to check
and see if the ending condition has been reached.

Well, once I’d gotten this far, I thought I’d better do things correctly. I
wrote two framing scripts, one for timing all the available scripts, the other
for testing them to make sure they work!

    
    my @numbers = 1..200, 10000..10200;
    
    sub MAIN(Str $perl6, *@scripts) {
        my %results;
        for @scripts -> $script {
            my $start = now;
            qqx/$perl6 $script { @numbers }/;
            my $end = now;
    
            %results{$script} = $end - $start;
        }
    
        for %results.pairs.sort(*.value) -> (:key($script), :value($time)) {
            say "$script: $time seconds";
        }
    }
    

  
This script takes as an argument a string that can be used to call a Perl 6
executable and a list of scripts to run. It runs the scripts using the
specified executable, and times them using p6′s `now` function. It then sorts
the results into order and prints them. (A [similar
script](https://github.com/colomon/perl6-collatz/blob/master/bin/testing-
harness.pl) I won’t post here tests each of them to make sure they are
returning correct results.)

In the new framework, the Collatz script has changed a bit. Instead of taking
a min and a max value and finding the longest Collatz sequence generated by a
number in that range, it takes a series of numbers and generates and reports
the length of the sequence for each of them. Here’s the sequence operator
script in its full new version:

    
    sub collatz-length(Int $start) { 
        +($start, { when * %% 2 { $_ / 2 }; when * !%% 2 { 3 * $_ + 1 }; } ... 1);
    }
    
    sub MAIN(*@numbers) {
        for @numbers -> $n {
            say "$n: " ~ collatz-length($n.Int);
        }
    }
    

  
For the rest of the scripts I will skip the `MAIN` sub, which is exactly the
same in each of them.

Framework established, I redid the recursive version starting from the new
sequence operator code.

    
    sub collatz-length(Int $n) {
        given $n {
            when 1       { 1 }
            when * %% 2  { 1 + collatz-length($_ div 2) }
            when * !%% 2 { 1 + collatz-length(3 * $_ + 1) }
        } 
    }
    

  
The sharp-eyed will notice this version is different from the first recursive
version above in two significant ways. This time I made the argument `Int $n`,
which instantly turned up a bit of a bug in all implementations thus far:
because I used `$_ / 2`, most of the numbers in the sequence were actually
rationals, not integers! This shouldn’t change the results, but is probably
less efficient than using `Int`s. Thus the second difference about, it now
uses `$_ div 2` to divide by 2. This version remains a great improvement over
the sequence operator version, running in 4.7 seconds instead of 13.3.
Changing ` when * !%% 2` to a simple `default` shaves another .3 seconds off
the running time.

Once I started wondering how much time was getting eaten up by the `when`
statements, rewriting that bit using the ternary operator was an obvious
choice.

    
    sub collatz-length(Int $start) { 
        +($start, { $_ %% 2 ?? $_ div 2 !! 3 * $_ + 1 } ... 1);
    }
    

  
Timing results: Basic sequence 13.4 seconds. Sequence with `div` 11.5 seconds.
Sequence with `div` and ternary 9.7 seconds.

That made me wonder what kind of performance I could get from a handcoded
loop.

    
    sub collatz-length(Int $n is copy) {
        my $length = 1;
        while $n != 1 {
            $n = $n %% 2 ?? $n div 2 !! 3 * $n + 1;
            $length++;
        }
        $length;
    }
    

  
That’s by far the least elegant of these, I think, but it gets great
performance: 3 seconds.

Switching back to the recursive approach, how about using the ternary operator
there?

    
    sub collatz-length(Int $n) {
        return 1 if $n == 1;
        1 + ($n %% 2 ?? collatz-length($n div 2) !! collatz-length(3 * $n + 1));
    }
    

  
This one just edges out the handcoded loop, 2.9 seconds.

Can we do better than that? How about memoization? `is cached` is supposed to
be part of Perl 6; neither implementation has it yet, but last year’s [Advent
calendar has a Rakudo
implementation](http://perl6advent.wordpress.com/2011/12/04/traits-meta-data-
with-character/) that still works. Using the last version changed to `sub
collatz-length(Int $n) is cached {` works nicely, but takes 3.4 seconds to
execute. Apparently the overhead of caching slows it down a bit.
Interestingly, the non-ternary recursive version does speed up with `is
cached`, from 4.4 seconds to 3.6 seconds.

Okay, instead of using a generic memoization, how about hand-coding one?

    
    sub collatz-length(Int $n) {
        return 1 if $n == 1;
        state %lengths;
        return %lengths{$n} if %lengths.exists($n);
        %lengths{$n} = 1 + ($n %% 2 ?? collatz-length($n div 2) !! collatz-length(3 * $n + 1));
    }
    

  
Bingo! 2.7 seconds.

I’m sure there are lots of other interesting approaches for solving this
problem, and encourage people to send them in. In the meantime, here’s my
summary of results so far:

Script

Rakudo

Niecza

[ bin/collatz-recursive-ternary-hand-cached.pl
](https://github.com/colomon/perl6-collatz/blob/master/bin/collatz-recursive-
ternary-hand-cached.pl)

2.5

1.7

[ bin/collatz-recursive-ternary.pl
](https://github.com/colomon/perl6-collatz/blob/master/bin/collatz-recursive-
ternary.pl)

3

1.7

[ bin/collatz-loop.pl
](https://github.com/colomon/perl6-collatz/blob/master/bin/collatz-loop.pl)

3.1

1.7

[ bin/collatz-recursive-ternary-cached.pl
](https://github.com/colomon/perl6-collatz/blob/master/bin/collatz-recursive-
ternary-cached.pl)

3.2

N/A

[ bin/collatz-recursive-default-cached.pl
](https://github.com/colomon/perl6-collatz/blob/master/bin/collatz-recursive-
default-cached.pl)

3.5

N/A

[ bin/collatz-recursive-default.pl
](https://github.com/colomon/perl6-collatz/blob/master/bin/collatz-recursive-
default.pl)

4.4

1.8

[ bin/collatz-recursive.pl
](https://github.com/colomon/perl6-collatz/blob/master/bin/collatz-
recursive.pl)

4.9

1.9

[ bin/collatz-sequence-ternary.pl
](https://github.com/colomon/perl6-collatz/blob/master/bin/collatz-sequence-
ternary.pl)

9.9

3.3

[ bin/collatz-sequence-div.pl
](https://github.com/colomon/perl6-collatz/blob/master/bin/collatz-sequence-
div.pl)

11.6

3.5

[ bin/collatz-sequence.pl
](https://github.com/colomon/perl6-collatz/blob/master/bin/collatz-
sequence.pl)

13.5

3.8

The table was generated from [timing-table-
generator.pl](https://github.com/colomon/perl6-collatz/blob/master/bin/timing-
table-generator.pl).

