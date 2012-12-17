Many people have heard of Perl 6, especially in the greater Perl community.
However, Perl 6 has a complicated ecosystem which can be a littled daunting,
so as a newcomer to the Perl 6 community myself, I thought I would share what
I’ve learned.

## How do I install Perl 6?

It’s simple; you can just download one of the existing implementations of the
language (as Perl 6 is a specification), build it, and install it! There are
several implementations out there right now, in various states of completion.
[Rakudo](http://www.rakudo.org/) is an implementation that targets Parrot, and
is the implementation that I will discuss most in this post. Niecza is another
implementation that targets the CLR (the .NET runtime). For more information
on these implementations and on other implementations, please see [Perl 6
Compilers](http://www.perl6.org/compilers/). Perl 6 is an ever-evolving
language, and any compiler that passes the official test suite can be
considered a Perl 6 implementation.

## You mentioned “Parrot”; what’s that?

[Parrot](http://www.parrot.org/) is a virtual machine that is designed to run
dynamically typed languages. Along with the virtual machine, it includes tools
for generating virtual machine code from intermediate languages (named PIR and
PASM), as well as a suite of tools to make writing compilers easier.

## What is Rakudo written in?

Rakudo itself is written primarly in Perl 6, with some bits of C for some of
the lower-level operations, like binding method arguments and adding
additional opcodes to the Parrot VM. It may seem strange to implement a Perl 6
compiler in Perl 6 itself; Rakudo uses NQP for building itself.

## What’s NQP?

NQP (or Not Quite Perl 6) is an implementation of Perl 6 that is focused on
creating compilers for the Parrot Compiler Toolkit. It is currently focused on
targetting Parrot, but in the future, it may support various compilation
targets, so you will be able to use Rakudo to compile your Perl 6 programs to
Parrot opcodes, a JVM class file, or perhaps Javascript so you can run it in
the browser. NQP is written in NQP, and uses a pre-compiled version of NQP to
compile itself.

I hope that this information was useful to you, dear reader, and that it helps
to clarify the different pieces of the Perl 6 ecosystem. As I learn more about
each piece, I intend to write blog posts that will hopefully help others to
get started contributing to Perl 6!

-Rob

