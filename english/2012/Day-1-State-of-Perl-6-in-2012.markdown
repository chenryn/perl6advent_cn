Welcome to another edition of your annual Perl 6 advent calendar.

As is tradition on the first of December, you can read a short overview over what has changed in the past year, and where we are standing now.

The list of major changes to the specification is pretty short. The IO subsystem has undergone a rewrite, and now much better reflects the realities in implementations, and actually has a measure of common sense applied. [S32::Exceptions](http://perlcabal.org/syn/S32/Exception.html) has gone through lots of changes (mostly extensions), and now there is a decent core of exception classes in Perl 6.

Both Rakudo and Niecza, the two major Perl 6 compilers, have matured a great deal. Contrary to last year, chances are pretty good that if your program works on one of the compilers, it also works on the other. Niecza also temporarily overtook Rakudo on the count of passing tests.

Niecza had a revamp of the roles implementation, has gained constant folding, awesome Unicode support in regexes, list comprehensions and a `no strict;` mode. To name just a few of the major changes.

Rakudo now supports heredocs, all phasers (special blocks like BEGIN, END, FIRST, …), longest-token matching in regexes, typed exceptions, much nicer backtraces and operator adverbs. And it now has a debugger, which is shipped with the Rakudo Star distribution.

The [module ecosystem](http://modules.perl6.org/) has grown a lot, and there is much more [documentation](http://doc.perl6.org/) for Perl 6 than a year ago.

So, after all these changes, where are we now?

Reports from production uses of Perl 6 are slowly starting to trickle in, and these days if your Perl 6 code has bugs, the chances are much higher that your code is to blame than the compilers. Perl 6 has never been this much fun to use. It surely has been a good and productive year for Perl 6, and we’re sure that this last month will continue the tradition. Have fun!
