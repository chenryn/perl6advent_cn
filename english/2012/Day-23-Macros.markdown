Syntactic macros. The Lisp gods of yore provided humanity with this invention,
essentially making Lisp a programmable programming language. Lisp adherents
often look at the rest of the programming world with pity, seeing them
fighting to invent wheels that were wrought and polished back in the sixties
when giants walked the Earth and people wrote code in all-caps.

And the Lisp adherents see that the rest of us haven’t even gotten to the best
part yet, the part with syntactic macros. We’re starting to get the hang of
automatic memory management, continuations, and useful first-class functions.
But macros are still absent from this picture.

In part, this is because in order to have proper syntactic macros, you
basically have to look like Lisp. You know, with the parentheses and all. Lisp
ends up having almost no syntax at all, making every program a very close
representation of a syntax tree. Which really helps when you have macros
starting to manipulate those same trees. Other languages, not really wanting
to look like Lisp, find it difficult-to-impossible to pull off the same trick.

The Perl languages love the difficult-to-impossible. Perl programmers publish
half a dozen difficult-to-impossible solutions to CPAN _before_ breakfast.
And, because Perl 6 is awesome and syntactic macros are awesome, Perl 6 has
syntactic macros.

It is known, Khaleesi.

## What are macros?

For reasons even I don’t fully understand, I’ve put myself in charge of
implementing syntactic macros in Rakudo. Implementing macros means
understanding them. Understanding them means my brain melts regularly. Unless
it fries. It’s about 50-50.

I have this habit where I come into the `#perl6` channel, and exclaiming
“macros are just X!” for various values of X. Here are some samples:

  * Macros are just syntax tree manipulators.
  * Macros are just “little compilers”.
  * Macros are just a kind of templates.
  * Macros are just routines that do code substitution.
  * Macros allow you to safely hand values back and forth between the compile-time world and the runtime world.

But the definition that I finally found that I like best of all comes from
[scalamacros.org](http://scalamacros.org/):

> Macros are functions that are called by the compiler during compilation.
Within these functions the programmer has access to compiler APIs. For
example, it is possible to generate, analyze and typecheck code.

While we only cover the “generate” part of it yet in Perl 6, there’s every
expectation we’ll be getting to the “analyze and typecheck” parts as well.

## Some examples, please?

Coming right up.

    
    macro checkpoint {
      my $i = ++(state $n);
      quasi { say "CHECKPOINT $i"; }
    }
    
    checkpoint;
    for ^5 { checkpoint; }
    checkpoint;

The `quasi` block is Perl 6′s way of saying “a piece of code, coming right
up!”. You just put your code in the `quasi` block, and return it from the
macro routine.

This code inserts “checkpoints” in our code, like little debugging messages.
There’s only three checkpoints in the code, so the output we’ll get looks like
this:

    
    CHECKPOINT 1
    CHECKPOINT 2
    CHECKPOINT 2
    CHECKPOINT 2
    CHECKPOINT 2
    CHECKPOINT 2
    CHECKPOINT 3

Note that the “code insertion” happens at compile time. That’s why we get five
copies of the `CHECKPOINT 2` line, because it’s the same checkpoint running
five times. If we had had a subroutine instead:

    
    sub checkpoint {
      my $i = ++(state $n);
      say "CHECKPOINT $i";
    }

Then the program would print 7 distinct checkpoints.

    
    CHECKPOINT 1
    CHECKPOINT 2
    CHECKPOINT 3
    CHECKPOINT 4
    CHECKPOINT 5
    CHECKPOINT 6
    CHECKPOINT 7

As a more practical example, let’s say you have logging output in your
program, but you want to be able to switch it off completely. The problem with
an ordinary logging subroutine is that with something like:

    
    LOG "The answer is { time-consuming-computation() }";

The `time-consuming-computation()` will run and take a lot of time even if
`LOG` subsequently finds that logging was turned off. (That’s just how
argument evaluation works in a non-lazy language.)

A macro fixes this:

    
    constant LOGGING = True;
    
    macro LOG($message) {
      if LOGGING {
        quasi { say {{{$message}}} };
      }
    }

Here we see a new feature: the `{{{ }}}` triple-block. (Syntax is likely to
change in the near future, see below.) It’s our way to mix template code in
the `quasi` block with code coming in from other places. Doing `say $message;`
would have been wrong, because `$message` is a syntax tree of the message to
be logged. We need to inject that syntax tree right into the `quasi`, and we
do that with a triple-block.

The macro _conditionally_ generates logging code in your program. If the
constant `LOGGING` is switched on, the appropriate logging code will replace
each `LOG` macro invocation. If `LOGGING` is off, each macro invocation will
be replaced by literally nothing.

Experience shows that running no code at all is very efficient.

## What are syntactic macros?

A lot of things are called “macros” in this world. In programming languages,
there are two big categories:

  * **Textual macros.** They substitute code on the level of the source code text. C’s macros, or Perl 5′s source filters, are examples.
  * **Syntactic macros.** They substitute code on the level of the source code syntax tree. Lisp macros are an example.

Textual macros are very powerful, but they represent the kind of power that is
just as likely to shoot half your leg off as it is to get you to your
destination. Using them requires great care, of the same kind needed for a
janitor gig at Jurassic Park.

The problem is that textual macros don’t _compose_ all that well. Bring in
more than one of them to work on the same bit of source code, and… all bets
are off. This puts severe limits on modularity. Textual macros, being what
they are, leak internal details all over the place. This is the big lesson
from Perl 5′s source filters, as far as I understand.

Syntactic macros compose wonderfully. The compiler is _already_ a pipeline
handing off syntax trees between various processing steps, and syntactic
macros are simply more such steps. It’s as if you and the compiler were two
children, with the compiler going “Hey, you want to play in my sandbox? Jump
right in. Here’s a shovel. We’ve got work to do.” A macro is a shovel.

And syntactic macros allow us to be _hygienic_, meaning that code in the macro
and code outside of the macro don’t step on each other’s toes. In practice,
this is done by carefully keeping track of the macros context and the
mainline’s context, and making sure wires don’t cross. This is necessary for
safe and large-scale composition. Textual macros don’t give us this option at
all.

## Future

Both of the examples in this post work already in Rakudo. But it might also be
useful to know where we’re heading with macros in the next year or so. The
list is in the approximate order I expect to tackle things.

  * **Un-hygiene.** While hygienic macros are the sane and preferable default, sometimes you _want_ to step on the toes of the mainline code. There should be an opt-out, and escape hatch. This is next up.
  * **Introspection.** In order to analyze and typecheck code, not just generate it, we need to be able to take syntax trees coming in as macro arguments, and look inside of them. There are no tools for that yet, and there’s no spec to guide us here. But I’m fairly sure people will want this. The trick is to come up with something that doesn’t tie us down to one compiler’s internal syntax-tree format. Both for the sake of compiler interoperability and future compatibility.
  * **Deferred declarations.** The sandbox analogy isn’t so frivolous, really. If you declare a class inside a `quasi` block, that declaration is limited (“sandboxed”) to within that `quasi` block. Then, when the code is injected somewhere in the mainline because of a macro invocation, it should actually run. Fortunately, as it happens, the Rakudo internals are factored in such a way that this will be fairly straightforward to implement.
  * **Better syntax.** The triple-block syntax is probably going away in favor of something better. The problem isn’t the syntax so much as the fact that it currently only works for terms. We want it to work for basically all syntactic categories. A solid proposal for this is yet to materialize, though.

With each of these steps, I expect us to find new and fruitful uses of macros.
Knowing my fellow Perl 6 developers, we’ll probably find some uses that will
shock and disgust us all, too.

## In conclusion

Perl 6 is awesome because it puts _you_, the programmer, in the driver seat.
Macros are simply more of that.

Implementing macros makes your brain melt. However, using them is relatively
straightforward.

