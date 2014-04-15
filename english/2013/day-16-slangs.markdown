## Day 16 – Slangs

by [tleich][4] use v6;
my $thing = "123abc";
say try $thing + 1; # this will fail

\{
    use v5;
    say $thing + 1 # will print 124
\}

Slangs are pretty interesting things in natural languages, so naturally they will be pretty awesome in computer languages as well. Without it the cross-language communication is like talking through a thin pipe, like it is when calling C functions. It _does_ work, but calling functions is not the only nor the most comfortable thing out there.

The example above shows that we create a variable in Perl 6 land and use it in a nested block, which derives from another language. (This does only work if the nested language is capable of handling the syntax, a dollar-sigilled variable in this case.)<br /> We use this other language on purpose: it provides a feature that we need to solve our task.<br /> I hope that slangs will pop up not just to provide functionality to solve a given problem, but also help in writing the code in a way that fits the nature of that said problem.

**How does that even work?**

The key is that the module that lets you switch to the slang provides a grammar and appropriate action methods. That is not different from how Perl 6 is implemented itself, or how JSON::Tiny works internally.<br /> The grammar will parse all statements in our nested block, and the actions are there to translate the parsed source code (text) into something a compiler can handle better: usually abstracted operations in form of a tree, called [AST][5].

The v5 slang compiles to QAST, which is the name of the AST that Rakudo uses. The benefit of that approach is that this data structure is already known by the guts of the Rakudo compiler. So our slang would just need to care about translating the foreign source code text into something known. The compiler takes this AST then and maps it to something the underlying backend understands.<br /> So it does not matter if we’re running on Parrot, on the JVM or something else, the slang’s job is done when it produced the AST.

**A slang was born.**

In March this year at the [GPW2013][6], I felt the need for something that glues both Perl 6 and Perl 5 together. There were many nice people that shared this urge, so I investigated how to do so.<br /> Then I found a Perl 5 parser in the [std][7] repository. Larry Wall took the Perl 6 parser years ago and modified it to be Perl 5 conform. The Perl 6 parser it is based on is the very same that Rakudo is built upon. So the first step was to take this Perl 5 grammar, take the action methods from Rakudo, and try to build something that compiles.<br /> (In theory this is all we needed: grammar + action = slang.)

I can’t quite remember whether it took one week or two, but then there was a hacked Rakudo that could say “Hallo World”. And it already insisted on putting parens around conditions for example. Which might be the first eye catcher for everyone when looking at both languages.<br /> Since then there was a lot of progress in merging in Perl 5′s test suite, and implementing and fixing things, and making it a [module][8] rather than a hacked standalone Rakudo-ish thing.

Today I can proudly say that it passes more than [4600 of roughly 45000 tests][9]. These 4600 passing tests are enough so you can play with it and feed it simple Perl 5 code. But the main work for the next weeks and months is to provide the core modules so that you can actually use a module from CPAN. Which, after all, was the main reason to create v5.

**What is supported at the moment?**

* all control structures like loops and conditions
* functions like shift, pop, chop, ord, sleep, require, …
* mathematical operations
* subroutine signatures that affect parsing
* pragmas like vars, warnings, strict
* core modules like Config, Cwd and English

**The main missing pieces that hurt are:**

* labels and goto
* barewords and pseudo filehandles
* [many many core modules][10]

Loop labels for `next LABEL`, `redo LABEL` and `last LABEL` will land soon in rakudo and v5. The other missing parts will take their time but will happen :o).

**The set goals of v5:**

* write Perl 5 code directly in Perl 6 code, usually as a closure
* allow Perl 6 lexical blocks inside Perl 5 ones
* make it easy to use variables declared in an outer block (outer means the other language here)
* provide the behaviour of Perl 5 operators and built-ins for v5 blocks only, nested Perl 6 blocks should not be affected
* and of course: make subs, packages, regexes, etc available to the other language

All of the statements above are already true today. If you do a numeric operation it will behave differently in a v5 block than a Perl 6 block like the example at the top shows. That is simply because in Perl 6 the `+` operator will dispatch to a subroutine called `&infix:<+>`, but in a v5 block it translates to `&infix:<P5+>`.

Oversimplified it looks a bit like this:

Perl 6/5 code:

1 + 2;
\{
    use v5;
    3 + 4
\}

Produced AST:

- QAST::CompUnit
    - QAST::Block 1 + 2; \{ use v5; 3 + 4 \}
        - QAST::Stmts 1 + 2; \{ use v5; 3 + 4 \}
            - QAST::Stmt
                - QAST::Op(call &amp;infix:&lt;+&gt;) +
                    - QAST::IVal(1)
                    - QAST::IVal(2)
            - QAST::Block \{ use v5; 3 + 4 \}
                - QAST::Stmts  use v5; 3 + 4 
                    - QAST::Stmt
                        - QAST::Op(call &amp;infix:&lt;P5+&gt;)
                            - QAST::IVal(3)
                            - QAST::IVal(4)

The nice thing about this is that you can use foreign operators (of the used slang) in your Perl 6 code. Like `&prefix:<P5+>("123hurz")` would be valid Perl 6 code that turn a string into a number even when there are trailing word characters.

To get v5 you should follow its [README][11], but be warned, at the moment this involves recompiling Rakudo.

**Conclusion:** When was the last time you’ve seen a language you could extend that easily? Right. I was merely astonished how easy it is to get started. Next on your TODO list: the COBOL slang. :o)


![][38]

  [4]: https://perl6advent.wordpress.com/author/tleich/ "View all posts by tleich"
  [5]: http://en.wikipedia.org/wiki/Abstract_syntax_tree "AST - wikipedia"
  [6]: http://act.yapc.eu/gpw2013/ "German Perl Workshop 2013"
  [7]: https://github.com/perl6/std/ "std repository - github"
  [8]: https://github.com/rakudo-p5/v5 "v5 module repository"
  [9]: https://github.com/rakudo-p5/v5/blob/master/STATUS.md "test suite stats"
  [10]: https://github.com/rakudo-p5/v5/blob/master/TODO_core_modules.md "TODO_core_modules.md"
  [11]: https://github.com/rakudo-p5/v5/blob/master/README.md "v5's README"
