# Introduction

This article aims to demonstrate how Whatever — one of the many interesting Perl 6 curiosities — could be useful to easily implement and use complex things like a layout manager. In a couple of words, a layout manager is the part of a graphical interface in charge of the spatial arrangement of objects like windows or widgets. For the sake of simplicity, the layout manager implemented in this article will comply with the following three rules:

* there are only two kinds of widgets: terminal or container, the latter can contain other widgets of either kind;
* a widget cannot be overlapped, except for containers which fully contain their sub-widgets; and
* only the height can be adjusted, this size can be either static, dynamic, or intentionally left unspecified.

# Usage

From the user's point-of-view, this layout manager aims to be as easy to use as possible. For example, it shouldn't be hard to specify such typical interface below, inspired from a text-based program. In this example, the interface and body widgets are containers, all the others are terminals:

    interface (X lines)
    +----> +------------------------------------------+
    |      | menu bar (1 line)                        |  body (remaining space)
    |      +------------------------------------------+ <----+
    |      | subpart 1 (1/3 of the remaining space)   |      |
    |      |                                          |      |
    |      |                                          |      |
    |      +------------------------------------------+      |
    |      | subpart 2 (remaining space)              |      |
    |      |                                          |      |
    |      |                                          |      |
    |      |                                          |      |
    |      |                                          |      |
    |      |                                          |      |
    |      +------------------------------------------+ <----+
    |      | status bar (1 line)                      |
    +----> +------------------------------------------+

The user don't know what the remaining space is in advance because such an interface is arbitrary resizable. As a consequence it should be specified as a non-predefined value; this is where * — the Whatever object — comes in handy. This object is interesting for two reasons:

* from the user's point-of-view, the definition of non-static sizes is as simple as: * / 3 for the subpart 1 (dynamic) and just * for the subpart 2 (unspecified); and
* from the developer's point-of-view, Perl 6 transforms automatically things like $size = * / 3 into a closure: x → x / 3. Then, it could be called like a regular function: $size($x).

That way, the previous GUI can be transliterated into the following lines of code:

    my $interface =
        Widget.new(name => 'interface', size => $x, sub-widgets => (
            Widget.new(name => 'menu bar', size => 1),
            Widget.new(name => 'main part', size => *, sub-widgets => (
                Widget.new(name => 'subpart 1', size => * / 3),
                Widget.new(name => 'subpart 2', size => *))),
            Widget.new(name => 'status bar', size => 1)));

# Implementation

The drawing of terminal widgets is straightforward since most of the work is done by containers. Those are in charge to compute the remaining space as well as to uniformly distribute widgets that have an unspecified size:

    class Widget {
        has $.name;
        has $.size is rw;
        has Widget @.sub-widgets;
    
        method compute-layout($remaining-space? is copy, $unspecified-size? is copy) {
            $remaining-space //= $!size;
    
            if @!sub-widgets == 0 {  # Terminal
                my $computed-size = do given $!size {
                    when Real     { $_                  };
                    when Callable { .($remaining-space) };
                    when Whatever { $unspecified-size   };
                }
    
                self.draw($computed-size);
            }
            else {  # Container
                my @static-sizes   =  grep Real,     @!sub-widgets».size;
                my @dynamic-sizes  =  grep Callable, @!sub-widgets».size;
                my $nb-unspecified = +grep Whatever, @!sub-widgets».size;
    
                $remaining-space -= [+] @static-sizes;
    
                $unspecified-size = ([-] $remaining-space, @dynamic-sizes».($remaining-space))
                                     / $nb-unspecified;
    
                .compute-layout($remaining-space, $unspecified-size) for @!sub-widgets;
            }
        }
    
        method draw(Real $size is copy) {
            "+{'-' x 25}+".say;
            "$!name ($size lines)".fmt("| %-23s |").say;
            "|{' ' x 25}|".say while --$size > 0;
        }
    }

Here, any Callable object can be used to specify a dynamic size, as far as it takes the computed remaining space as argument. That means it is possible to specify more sophisticated dynamic size by passing a code Block. For example, `{ max(5, $^x / 3) }` ensures the widget has a proportional size that can't decrease below 5.

# Conclusion

It's time to check if this trivial layout manager works correctly both in Rakudo and Niecza, the two most advanced implementations of Perl 6. The following test is rather simple, it creates and draws an interface, then resize it and draws it again:

    my $interface =
        Widget.new(name => 'interface', size => 11, sub-widgets => (
            Widget.new(name => 'menu bar', size => 1),
            Widget.new(name => 'main part', size => *, sub-widgets => (
                Widget.new(name => 'subpart 1', size => * / 3),
                Widget.new(name => 'subpart 2', size => *))),
            Widget.new(name => 'status bar', size => 1)));
    
    $interface.compute-layout;  # Draw
    $interface.size += 3;       # Resize
    $interface.compute-layout;  # Redraw

The results before and after resizing are respectively displayed below. They are close enough from the initial mockup, n'est-ce pas?

    +-------------------------+            +-------------------------+
    | menu bar (1 lines)      |            | menu bar (1 lines)      |
    +-------------------------+            +-------------------------+
    | subpart 1 (3 lines)     |            | subpart 1 (4 lines)     |
    |                         |            |                         |
    |                         |            |                         |
    +-------------------------+            |                         |
    | subpart 2 (6 lines)     |            +-------------------------+
    |                         |            | subpart 2 (8 lines)     |
    |                         |            |                         |
    |                         |            |                         |
    |                         |            |                         |
    |                         |            |                         |
    +-------------------------+            |                         |
    | status bar (1 lines)    |            |                         |
                                           |                         |
                                           +-------------------------+
                                           | status bar (1 lines)    |

Finally, the implementation of such a flexible program is really simple in Perl 6: everything is already there, in the core language. Obviously, this trivial layout manager isn't ready for prime-time since a lot of things are missing: sanity checks, multiple dimensions, … but those are left as exercises to you, the reader ;) For any questions or comments, feel free to meet Perl 6 fellows on IRC (#perl6 on freenode).

# Bonus

As seen previously, `$!size` can be Whatever, but it can't be whatever you want. For example, a negative Real or a string are not correct values. Once again Perl 6 provides a simple yet powerful feature: constrained types. In a couple of words this permits to define new types from a set of constraints:

    subset PosReal of Real where * >= 0;
    subset Size where {   .does(PosReal)
                       or .does(Callable) and .signature ~~ :(PosReal --> PosReal)
                       or .does(Whatever) };
    
    has Size $.size is rw;
