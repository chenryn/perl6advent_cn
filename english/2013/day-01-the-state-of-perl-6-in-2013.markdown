## Day 01 – The State of Perl 6 in 2013

by [Moritz][4]

Welcome to the 2013 Perl 6 advent calendar!

In Perl 6 land, 2013 will be remembered as the year that brought proper concurrency support.

But I'm getting ahead of myself.

There is also sad news. Niecza, the Perl 6 compiler on the CLR (.NET/Mono) platform, and the Perl 6 compiler with the best runtime characteristics, had its last release in March. Since then there were a few maintenance patches and new built-in types and routines, but little in terms of actual compiler features.

A little later, Rakudo gained support to run on the Java Virtual machine. There are still some bits missing, mostly notably support for the native call interface, but all in all it works quite well, passes more than 99.9% of the tests that Rakudo on Parrot passes, and has two key advantages: it is [much faster][5] [at run time][6], and has proper concurrency/parallelism support.

Jonathan Worthington prototyped and implemented it, and later specified it in [S17][7], which again led to lots of improvements. Stay tuned for more advent calendar posts on the JVM and concurrency/parallelism topics.

Another big news this year was the revelation of [MoarVM][8], a virtual machine designed to run Perl 6. With the JVM's high startup time and Parrot being mostly unmaintained and having lots of unsolved problems, there is a niche to be filled. NQP, the "Not Quite Perl" Perl 6 compiler used to bootstrap Rakudo already runs on MoarVM; Rakudo support for MoarVM is on its way, and progressing well so far.

There was also lots of progress in terms of built-in types likes Set and Bag, and IO::Path for handling path and directory objects.

As a developer and early adopter, I find Perl 6 to be pleasant to work with. In 2013 it has gotten easier to use, due to better error reporting and improved IO.


![][41]

  [4]: https://perl6advent.wordpress.com/author/foobar123/ "View all posts by Moritz"
  [5]: http://cyberuniverses.com/pray/#pray-news-20131127
  [6]: https://justrakudoit.wordpress.com/2013/08/02/rakudo-performance/
  [7]: http://perlcabal.org/syn/S17.html
  [8]: https://6guts.wordpress.com/2013/05/31/moarvm-a-virtual-machine-for-nqp-and-rakudo/
