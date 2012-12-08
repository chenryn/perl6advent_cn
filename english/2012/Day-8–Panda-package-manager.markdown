### [Perl 6 Advent Calendar](http://perl6advent.wordpress.com) -- [Day 8 –
Panda package manager](http://perl6advent.wordpress.com/2012/12/08/day-8
-panda-package-manager/)

Perl 6 is not just the language. While without modules it can do more than
Perl 5, modules can make life easier. About two years ago [neutro was
discussed on this blog](http://perl6advent.wordpress.com/2010/12/09/day-9
-–-the-module-ecosystem/). I’m not going to talk about it, as it’s deprecated
today.

Today, the standard way of installing modules is the panda utility. If you’re
using Rakudo Star, you should have it already installed (try the panda command
in console to check it). After running it and waiting a few seconds, you
should see help for the panda utility.

    
    $ panda
    Usage:
      panda [--notests] [--nodeps] install [<modules> ...] -- Install the specified modules
      panda [--installed] [--verbose] list -- List all available modules
      panda update -- Update the module database
      panda info [<modules> ...] -- Display information about specified modules
      panda search <pattern> -- Search the name/description

As you can see, it doesn’t have many options (it’s actually similar to
RubyGems or cpanminus in its simplicity). You can see the current list of
modules at Perl 6 Modules page. Let’s say you would want to parse an INI file.
First, you can find module for it using the search command.

    
    $ panda search INI
    JSON::Tiny               *          A minimal JSON (de)serializer
    Config::INI              *          .ini file parser and writer module for
                                        Perl 6
    MiniDBI                  *          a subset of Perl 5 DBI ported to Perl 6
                                        to use while experts build the Real Deal
    Class::Utils             0.1.0      Small utilities to help with defining
                                        classes

Config::INI is module you want. Other modules were found because my query
wasn’t specific enough and found “ini” in other words (m**ini**mal,
M**ini**DBI and def**ini**ng). Config::INI isn’t part of Rakudo Star, so you
have to install it.

Panda installs modules globally when you have write access to the installation
directory, locally otherwise. Because of that you can use panda even when Perl
6 is installed globally without installing modules like local::lib, like you
have to in Perl 5.

    
    $ panda install Config::INI
    ==> Fetching Config::INI
    ==> Building Config::INI
    Compiling lib/Config/INI.pm
    Compiling lib/Config/INI/Writer.pm
    ==> Testing Config::INI
    t/00-load.t .... ok
    t/01-parser.t .. ok
    t/02-writer.t .. ok
    All tests successful.
    Files=3, Tests=55, 3 wallclock secs ( 0.04 usr 0.00 sys + 2.38 cusr 0.14 csys = 2.56 CPU)
    Result: PASS
    ==> Installing Config::INI
    ==> Succesfully installed Config::INI

After the module has been installed, you can update it as easily – by
installing it. Currently panda cannot automatically upgrade modules, but after
a module has been updated (you can watch repositories on GitHub to know when
it happens – every module is available on GitHub), you can easily upgrade it
by reinstalling the module.

When a module was installed, you can check if it works by trying to use it.
This is a sample script that can be used to convert INI file into a Perl 6
data structure.

    
    #!/usr/bin/env perl6
    use Config::INI;
    multi sub MAIN($file) {
        say '# your INI file as seen by Perl 6';
        say Config::INI::parse_file($file).perl;
    }

  
[![](http://feeds.wordpress.com/1.0/comments/perl6advent.wordpress.com/1596/)]
(http://feeds.wordpress.com/1.0/gocomments/perl6advent.wordpress.com/1596/) ![
](http://stats.wordpress.com/b.gif?host=perl6advent.wordpress.com&blog=1074007
3&post=1596&subd=perl6advent&ref=&feed=1)

_[December 08, 2012 12:49](http://perl6advent.wordpress.com/2012/12/08/day-8
-panda-package-manager/)_

