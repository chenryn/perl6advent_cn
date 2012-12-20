Today, let’s talk about DSLs.

## Post from the past: a motivating example

Two years ago I wrote [a blog post about
Nim](http://strangelyconsistent.org/blog/the-thing-with-nim), a game played
with piles of stones. I just put in ASCII diagrams of the actual Nim stone
piles, telling myself that if I had time, I would put in fancy SVG diagrams,
generated with Perl 6.

Naturally, I didn’t have time. My self-imposed deadline ran out, and I
published the post with simple ASCII diagrams.

But time is ever-regenerative, and there for people who want it. So, let’s
generate some fancy SVG diagrams with Perl 6.

## Have bit array, want SVG

What do we need, exactly? Well, a subroutine that takes an array of piles as
input and generates an SVG file would be a really good start.

Let’s take the last “image” in [the post](http://strangelyconsistent.org/blog
/the-thing-with-nim) as an example:

    
    3      OO O
    4 OOOO
    5 OOOO    O

For the moment, let’s ignore the numbers at the left margin; they’re just
counting stones. We summarize the piles themselves as a kind of bitmap, which
also forms the input to the function:

    
    my @piles =
        [0, 0, 0, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 1, 0, 1, 1, 0, 1],
        [1, 1, 1, 1, 0, 0, 0, 0, 1];
    
    nim-svg(@piles);

At this point, we need only create the `nim-svg` function itself, and make it
render SVG from this bitmap. Since I’ve long since tired of outputting SVG by
hand, I use the [SVG module](https://github.com/moritz/svg), which comes
bundled with Rakudo Star.

    
    use SVG;
    
    sub nim-svg(@piles) {
        my $width = max map *.elems, @piles;
        my $height = @piles.elems;
    
        my @elements = gather for @piles.kv -> $row, @pile {
            for @pile.kv -> $column, $is_filled {
                if $is_filled {
                    take 'circle' => [
                        :cx($column + 0.5),
                        :cy($row + 0.5),
                        :r(0.4)
                    ];
                }
            }
        }
        
        say SVG.serialize('svg' => [ :$width, :$height, @elements ]);
    }

I think you can follow the logic in there. The subroutine simply iterates over
the bitmap, turning 1s into circles with appropriate coordinates.

## That’s it?

Well, this will indeed generate an SVG image for us, with the stones correctly
placed. But let’s look again at the input that helped create this image:

    
        [0, 0, 0, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 1, 0, 1, 1, 0, 1],
        [1, 1, 1, 1, 0, 0, 0, 0, 1];

Clearly, though we can discern the stones and gaps in there if we squint in a
bit-aware programmer’s fashion, the input isn’t… visually attractive. (The
zeroes even look like stones, even though they’re gaps!)

## We can do better

Instead of using a bit array, let’s start from the desired SVG image and try
to make the input look like that.

So, this is what I would prefer to write instead of a bitmask:

    
    nim {
      _ _ _ _ _ _ _ _ o;
      o o o o _ o o _ o;
      o o o o _ _ _ _ o;
    }

That’s better. That looks more like my original ASCII diagram, while still
being syntactic Perl 6 code.

## Making a DSL

Wikipedia talks about a DSL as a language “dedicated to a particular problem
domain”. Well, the above way of specifying the input would be a DSL dedicated
to solving the draw-SVG-images-of-Nim-positions domain. (Admittedly a fairly
narrow domain. But I’m mostly out to show the potential of DSLs in Perl 6, not
to change the world with this particular DSL.)

Now that we have the desired end state, how do we connect the wires and make
the above work? Clearly we need to declare three subroutines: `nim`, `_`, `o`.
(Yes, you can name a subroutine `_`, no sweat.)

    
    sub nim(&block) {
        my @*piles;
        my @*current-pile;
    
        &block();
        finish-last-pile();
        
        nim-svg(@*piles);
    }
    
    sub _(@rest?) {
        unless @rest {
            finish-last-pile();
        }
        @*current-pile = 0, @rest;
        return @*current-pile;
    }
    
    sub o(@rest?) {
        unless @rest {
            finish-last-pile();
        }
        @*current-pile = 1, @rest;
        return @*current-pile;
    }

## Ok… explain, please?

A couple of things are going on here.

  * The two variables `@*piles` and `@*current-pile` are _dynamic variables_ which means that they are visible not just in the current lexical scope, but also in all subroutines called before the current scope has finished. Notably, the two subroutines `_` and `o`.
  * The two subroutines `_` and `o` take an optional parameter. On each row, the rightmost `_` or `o` acts as a silent “start of pile” marker, taking the time to do a bit of bookkeeping with the piles, storing away the last pile and starting on a new one.
  * Each row in the DSL-y input basically forms a chain of subroutine calls. We take this into account by both incrementally building the `@*current-pile` array at each step, all the while returning it as (possible) input for the next subroutine call in the chain.

And that’s it. Oh yeah, we need the bookkeeping routine `finish-last-pile`,
too:

    
    sub finish-last-pile() {
        if @*current-pile {
            push @*piles, [@*current-pile];
        }
        @*current-pile = ();
    }

## So, it works?

Now, the whole thing works. We can turn this DSL-y input:

    
    nim {
      _ _ _ _ _ _ _ _ o;
      o o o o _ o o _ o;
      o o o o _ _ _ _ o;
    }

…into this SVG output:

    
    <svg
      xmlns="http://www.w3.org/2000/svg"
      xmlns:svg="http://www.w3.org/2000/svg"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      width="9" height="3">
    
      <circle cx="8.5" cy="0.5" r="0.4" />
      <circle cx="0.5" cy="1.5" r="0.4" />
      <circle cx="1.5" cy="1.5" r="0.4" />
      <circle cx="2.5" cy="1.5" r="0.4" />
      <circle cx="3.5" cy="1.5" r="0.4" />
      <circle cx="5.5" cy="1.5" r="0.4" />
      <circle cx="6.5" cy="1.5" r="0.4" />
      <circle cx="8.5" cy="1.5" r="0.4" />
      <circle cx="0.5" cy="2.5" r="0.4" />
      <circle cx="1.5" cy="2.5" r="0.4" />
      <circle cx="2.5" cy="2.5" r="0.4" />
      <circle cx="3.5" cy="2.5" r="0.4" />
      <circle cx="8.5" cy="2.5" r="0.4" />
    </svg>

Yay!

## Summary

The principles I used in this post are fairly easy to generalize. Start from
your desired DSL, and create the subroutines to make it happen. Have dynamic
variables handle the communication between separate subroutines.

DSLs are nice because they allow us to shape the code we’re writing around the
problem we’re solving. Using relatively little “adapter code”, we’re left to
focus on describing and solving problems in a natural way, making the
programming language rise to our needs instead of lowering ourselves down to
its needs.

