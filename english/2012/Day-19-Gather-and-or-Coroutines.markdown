Today I’ll write about coroutines, gather-take and why they are as much fun as
one another. But since it’s all about manipulating control flow, I took the
liberty to reorganize the control flow of this advent post, so coroutines will
finally appear somewhere at the end of it. In the meantime I’ll introduce the
backstory, the problems that coroutines solved and how it looks from the Perl
6 kitchen.

LWP::Simple is all fun and games, but sometimes you can’t afford to wait for
the result to come. It would make sense to say “fetch me this webpage and drop
me a note when you’re done with it”. That’s non trivial though; LWP::Simple is
a black box, which we tell “get() this, get() that” and it gives us the result
back. There is no possible way to intercept the internal data it sends there
and around. Or is there?

If you look at Perl 5′s AnyEvent::HTTP, you’ll see that it reimplemented the
entire HTTP client to have it non-blocking. Let’s see if we can do better than
that.

First thing, where does LWP::Simple actually block? Behind our backs it uses
the built-in IO::Socket::INET class. When it wants data from it, it calls
.read() or .recv() and patiently waits until they’re done. If only we could
somehow make it not rely on those two directly, hmm…

„I know!”, a gemstone-fascinated person would say, „We can monkey-patch
IO::Socket::INET”. And then we have two problems. No, we’ll go the other way,
and follow the glorious path of Dependency Injection.

That sounds a bit scary. I’ve heard about as many definitions of Dependency
Injection as many people I know. The general idea is to not create objects
inside other objects directly; it should be possible to supply them from the
outside. I like to compare it to elimination of „magic constants”. No one
likes those; if you think of classes as another kind of magic constants which
may appear in somebody else’s code, this is pretty much what this is about. In
our case it looks like this:

    
    # LWP::Simple make_request
    my IO::Socket::INET $sock .= new(:$host, :$port);
    

There we go. “IO::Socket::INET” is the magic constant here; if you want to use
a different thing, you’re doomed. Let’s mangle it for a bit and allow the
socket class to come from the outside.

We’ll add an attribute to LWP::Simple, let’s call it $!socketclass

    
    has $.socketclass = IO::Socket::INET;
    

If we don’t supply any, it will just fallback to IO::Socket::INET, which is a
sensible default. Then, instead of the previous .new() call, we do

    
    my $sock = $!socketclass.new(:$host, :$port);
    

The actual patch ([https://github.com/tadzik/perl6-lwp-
simple/commit/93c182ac2](https://github.com/tadzik/perl6-lwp-
simple/commit/93c182ac2)) is a bit more complicated, as LWP::Simple supports
calling get() not only on constructed objects but also on type objects, which
have no attributes set, but we only care about the part shown above. We have
an attribute $!socketclass, which defaults to IO::Socket::INET but we’re free
to supply another class – dependency-inject it. Cool! So in the end it’ll look
like this:

    
    class Fakesocket is IO::Socket::INET {
        method recv($) {
            note 'We intercepted recv()';
            callsame;
        }
    
        method read($) {
            note 'We intercepted read()';
            callsame;
        }
    }
    
    # later
    my $lwp = LWP::Simple.new(socketclass => Fakesocket);
    

And so our $lwp is a fine-crafted LWP::Simple which could, theorically, give
the control flow back to us while it waits for read() and recv() to finish.
So, how about we put theory into practice?

### Here start the actual coroutines, sorry for being late :)

What do we really need in our modified recv() and read()? We need a way to say
„yeah, if you could just stop executing and give time to someone else, that
would be great.” Oh no, but we have no threads! Luckily, we don’t need any.
Remember lazy lists?

    
    my @a := gather { for 1..* -> $n { take $n } }
    

So on one hand we run an infinite for loop, and on the other we have a way to
say „give back what you’ve come up with, I’ll catch up with you later”. That’s
what take() does: it temporarily jumps out of the gather block, and is ready
to get back to it whenever you want it. Do I hear the sound of puzzles
clicking together? That’s exactly what we need! Jump out of the execution flow
and wait until we’re asked to continue.

    
    class Fakesocket is IO::Socket::INET {
        method recv($) {
            take 1;
            callsame;
        }
    
        method read($) {
            take 1;
            callsame;
        }
    }
    
    # later
    my @a := gather {
        $lwp.get("http://jigsaw.w3.org/HTTP/300/301.html");
        take "done";
    }
    
    # give time to LWP::Simple, piece by piece
    while ~@a.shift ne "done" {
        say "The coroutine is still running"
    }
    say "Yay, done!";
    

There we go! We just turned LWP::Simple into a non-blocking beast, using
almost no black magic at all! Ain’t that cool.

We now know enough to create some syntactic sugar around it all. Everyone
likes sugar.

    
    module Coroutines;
    my @coroutines;
    enum CoroStatus <still_going done>;
    
    sub async(&coroutine) is export {
        @coroutines.push($(gather {
            &coroutine();
            take CoroStatus::done;
        }));
    }
    
    #= must be called from inside a coroutine
    sub yield is export {
        take CoroStatus::still_going;
    }
    
    #= should be called from mainline code
    sub schedule is export {
        return unless +@coroutines;
        my $r = @coroutines.shift;
        if $r.shift ~~ CoroStatus::still_going {
            @coroutines.push($r);
        }
    }
    

We maintain a list of coroutines currently running. Our async() sub just puts
a block of code in the execution queue. Then every call to yield() will make
it jump back to the mainline code. schedule(), on the other hand, will pick
the first available coroutine to be run and will give it some time to do
whatever it wants.

Now, let us wait for the beginning of the post to catch up.

