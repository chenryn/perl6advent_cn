Recently I was unpacking some boxes of books and came across a book entitled
"[BASIC Computer Programs for the Home](http://www.amazon.com/Basic-Computer-
Programs-Charles-Sternberg/dp/0810451549)" by Charles D. Sternberg. Apparently
my father had purchased this book in the early 1980s and had given it to me.
In any case, my name was scrawled in the front cover in the manner an
adolescent me would have done.

Mostly this book is filled with simple BASIC programs that manage simple
databases of various things: recipes, household budget, address book, music
collections, book collections, school grades, etc. But the program that caught
my eye and made me think of the Perl 6 Advent Calendar was one for printing a
calendar starting at a particular month.

Now, the version in this book is a little simple in that it asks for the
starting month, year, the day of the week that the first month starts on, and
how many months to print. I wanted something a little more like the Unix
utility cal(1) program. Luckily, Perl 6 has date handling classes as part of
the [specification](http://perlcabal.org/syn/S32/Temporal.html) and both major
implemenations, [Rakudo and ](https://github.com/rakudo)Niecza, have actual
implementations of these which should make creating the calendar quite easy.

For reference, the output of the Unix cal(1) utility looks like this:

    
           December 2012
        Su Mo Tu We Th Fr Sa
                           1
         2  3  4  5  6  7  8
         9 10 11 12 13 14 15
        16 17 18 19 20 21 22
        23 24 25 26 27 28 29
        30 31                 

It also has some options to change the output in various ways, but I just want
to focus on reproducing the above basic output.

I'll need a list of month names and weekday abbreviations:

    
        constant @months = <January February March April May June July
                            August September October November December>;
        constant @days = <Su Mo Tu We Th Fr Sa>;

And it looks like the month and year are centered above the days of the week.
Generating a calendar for May shows this to be the case, so I'll need a
routine that centers text:

    
        sub center(Str $text, Int $width) {
            my $prefix = ' ' x ($width - $text.chars) div 2;
            my $suffix = ' ' x $width - $text.chars - $prefix.chars;
            return $prefix ~ $text ~ $suffix;
        }

Now, the mainline code needs two things: a month and a year. From this it
should be able to generate an appropriate calendar. But, we should have a
reasonable default for these values I think. Today's month and year seem
reasonable to me:

    
        sub MAIN(:$year = Date.today.year, :$month = Date.today.month) {

but if it's not today's month and year, then it's some arbitrary month and
year we need info about. To do this we construct a new Date object from the
month and year given.

    
            my $dt = Date.new(:year($year), :month($month), :day(1) );

Looking at the calendar generated for December, it seems like we may actually
output up to 6 rows of numbers since the month can start and end on a partial
week. In order to implement this, I think I'll need some "slots" for each day.
Each slot will either be empty or will contain the day of the month. The
number of empty slots at the beginning of the month correspond to the day of
the week that the first of the month occurs on. If the first is on Sunday,
there will be 0 empty slots, if the first is on a Monday there will be 1 empty
slot, if the first is on a Tuesday, there will be 2 empty slots, etc. This is
remarkably similar to the number we get when we interrogate a Date object for
the day of the week. The only wrinkle is that it returns 7 for Sunday when we
actually need a 0. That's easily remedied with a modulus operator however:

    
            my $dt = Date.new(:year($year), :month($month), :day(1) );
            my $ss = $dt.day-of-week % 7;
            my @slots = ''.fmt("%2s") xx $ss;

That gives us the empty slots at the beginning, but what about the ones that
actually contain the days of the month? Easy enough, we'll just generate a
number for each day of the month using the Date object we created earlier.

    
            my $days-in-month = $dt.days-in-month;
            for $ss ..^ $ss + $days-in-month {
                @slots[$_] = $dt.day.fmt("%2d");
                $dt++
            }

Now we've got an array with appropriate values in the appropriate positions,
all that's left is to actually output the calendar. Using the header line for
our weekdays as a metric for the width of the calendar, and the routine we
created for centering text, we can output the header portion of the calendar:

    
            my $weekdays = @days.fmt("%2s").join: " ";
            say center(@months[$month-1] ~ " " ~ $year, $weekdays.chars);
            say $weekdays;

Then we iterate over each slot and output the appropriate values. If we've
reached the end of the week or the end of the month, we output a newline:

    
            for @slots.kv -> $k, $v {
                print "$v ";
                print "\n" if ($k+1) %% 7 or $v == $days-in-month;
            }

Putting it all together, here is the final program:

    
        #!/usr/bin/env perl6
    
        constant @months = <January February March April May June July
                            August September October November December>;
        constant @days = <Su Mo Tu We Th Fr Sa>;
    
    
        sub center(Str $text, Int $width) {
            my $prefix = ' ' x ($width - $text.chars) div 2;
            my $suffix = ' ' x $width - $text.chars - $prefix.chars;
            return $prefix ~ $text ~ $suffix;
        }
    
        sub MAIN(:$year = Date.today.year, :$month = Date.today.month) {
            my $dt = Date.new(:year($year), :month($month), :day(1) );
            my $ss = $dt.day-of-week % 7;
            my @slots = ''.fmt("%2s") xx $ss;
    
            my $days-in-month = $dt.days-in-month;
            for $ss ..^ $ss + $days-in-month {
                @slots[$_] = $dt.day.fmt("%2d");
                $dt++
            }
    
            my $weekdays = @days.fmt("%2s").join: " ";
            say center(@months[$month-1] ~ " " ~ $year, $weekdays.chars);
            say $weekdays;
            for @slots.kv -> $k, $v {
                print "$v ";
                print "\n" if ($k+1) %% 7 or $v == $days-in-month;
            }
        }

Normally, cal(1) will highlight today's date on the calendar. That's a feature
I left out of my calendar implementation but it could easily be added with
[Term::ANSIColor](https://github.com/tadzik/perl6-Term-ANSIColor/). Also,
there's a little bit of coupling between the data being generated in the slots
and the output processing (the slots are all formatted to be 2 characters wide
in anticipation of the output). There are some other improvements that could
be done, but for a first cut at a calendar in Perl 6, I'm happy. :-)

