Perl 6 has great support for functions. It packs function signatures full with awesome, and lets you have your cake and eat it a couple of times over with all the ways you can specify a function. You can specify parameter types, optional parameters, named parameters, and even those cool where clauses. If I didn’t know better, I’d suspect Perl 6 was compensating for some predecessors rather rudimentary handling of parameters. (*cough* `@_` *cough*)

Among all these other things, Perl 6 also allows you to define functions without naming them.

    sub { say "lol, I'm so anonymous!" }

How is this useful? If you can’t name the function, you can’t call it, right? Wrong.

You can store the function in a variable. Or return it from another function. Or pass it to another function. In fact, when you don’t name your function, the focus becomes much more what code you’re going to run later. Like an executable “to do”-list.

Of course, Perl 5 has anonymous functions, too. With exactly the same syntax, even. In fact, all the big languages do anonymous functions, according to [this list of languages](https://en.wikipedia.org/wiki/Anonymous_function#List_of_languages) on Wikipedia. Except, it seems, the historically significant languages C and Pascal. And the more modern but lumbering Java. “Planned for Java 8″. Haha, Java, catch up! Even C++ has them now.

How important are anonymous functions? Very. In the 1930s, Alan Turing showed how all computer processes could be simulated using just a pre-programmed machine that looks like a tape recorder, reading and writing values on a really long tape. (The Turing Machine.) Meanwhile, across the Atlantic, Alonzo Church showed how all computer processes could be simulated using just anonymous functions, no tape recorder required. (Lambda calculus.) It’s all quite elegant.

Later languages like Lisp and Scheme lean heavily on anonymous functions as a key component in the language. And lately a scrappy language called JavaScript, which also leans heavily on anonymous functions, has taken over the world while we were all busy surfing the web.

But let’s talk possibilities here. What can anonymous functions do for us? And how would it look in Perl 6?

Well, take sorting as a famous example. You could imagine Perl 6 having a `sort_lexicographically` function and a `sort_numerically` function. But it doesn’t. It has a sort function. When you want it to sort in a certain way, you just pass an anonymous function to it.

    my @sorted_words = @words.sort({ ~$_ });
    my @sorted_numbers = @numbers.sort({ +$_ });

(Technically, those are blocks, not functions. But the difference isn’t significant if you’re not planning to return anywhere inside.)

And of course it goes further than just those two sort orders. You could sort by shoe size, or maximum ground speed, or decreasing likelihood of spontaneous combustion. All because you can pass in any logic as an argument. Object-oriented people are very proud of this pattern, and call it “dependency injection”.

Come to think of it, `map` and `grep` and `reduce` all depend on this kind of function-passing. We sometimes refer to passing functions to functions as “higher order programming”, as if it was only something people with special privileges should be doing. But in fact it’s a very useful and broadly applicable technique.

The above examples all run the anonymous functions as part of their own execution. But there’s no need to restrict ourselves to this. We can create functions, return them, and then run them later:

    sub make_surprise_for($name) {
        return sub { say "Sur-priiise, $name!" };
    }
    
    my $reveal_surprise = make_surprise_for("Finn");    # nothing happens, yet
    # ...wait for it...
    # ...wait...
    # ...waaaaaaait...
    $reveal_surprise();        # "Sur-priiise, Finn!"

The function in `$reveal_surprise` remembers the value of `$name` even though the original function passing it in has exited long ago. That’s pretty nice. This effect is referred to as the anonymous function closing over the variable `$name`. But there’s no need to get technical — the long and short of it is “it’s awesome”.

And in fact, it feels quite natural if we just look at anonymous functions aside other staple storage mechanisms such as arrays and hashes. All of these can be stored in variables, passed as arguments or returned from functions. An anonymous array allows you to store a sequence of things for later. An anonymous hash allows you to store mappings/translations of things for later. An anonymous function allows you to store calculations or behavior for later.

Later this month, I’ll go through how to exploit dynamic scoping in Perl 6 to create nice DSL-y interfaces. We’ll see how anonymous functions come into play there as well.
