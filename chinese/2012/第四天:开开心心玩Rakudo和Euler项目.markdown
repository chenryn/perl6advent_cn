Perl6 实现的领先者 Rakudo ，目前还不完美，说起性能也尤其让人尴尬。然而先行者不会问“他快么？”，而会问“他够快么？”，甚至是“我怎样能帮他变得更快呢？”。

为了说服你Rakudo已经能做到足够快了。我们准备尝试做一组[Euler项目](http://projecteuler.net/)测试。其中很多涉及强行的数值计算，Rakudo目前还不是很擅长。不过我们可没必要就此顿足：语言性能降低了，程序员就要更心灵手巧了，这正是乐趣所在啊。

_所有的代码都是在Rakudo 2012.11上测试通过的。_

We’ll start with something simple:
先从一些简单的例子开始：

# 问题2

    想想斐波那契序列里数值不超过四百万的元素，计算这些值的总和。

办法超级简单：

    say [+] grep * %% 2, (1, 2, *+* ...^ * > 4_000_000);

## 运行时间：0.4秒

注意怎样使用操作符才能让代码即紧凑又保持可读性(当然这点大家肯定意见不一)。我们用了：

* 无论如何用 * 创建 lambda 函数
* 用序列操作符`...^`来建立斐波那契序列
* 用整除操作符`%%`来过滤元素
* 用`[+]`做reduce操作计算和

当然，没人强制你这样疯狂的使用操作符 -- 香草(vanilla)命令式的代码也没问题：

# 问题3

    600851475143的最大素因数是多少？

命令式的解决方案是这样的：

    sub largest-prime-factor($n is copy) {
        for 2, 3, *+2 ... * {
            while $n %% $_ {
                $n div= $_;
                return $_ if $_ > $n;
            }
        }
    }

    say largest-prime-factor(600_851_475_143);

## 运行时间：2.6秒

注意用的`is copy`，因为 Perl6 的绑定参数默认是只读的。还有用了整数除法`div`，而没用数值除法的`/`。

到目前为止都没有什么特别的，我们继续：

# 问题53

    n从1到100， <sup>n</sup>C<sub>r</sub>的值，不一定要求不同，有多少大于一百万的？

我们将使用流入操作符`==>`来分解算法成计算的每一步：

    [1], -> @p { [0, @p Z+ @p, 0] } ... * # 生成杨辉三角
    ==> (*[0..100])()                     # 生成0到100的n行
    ==> map *.list                        # 平铺成一个列表
    ==> grep * > 1_000_000                # 过滤超过1000000的数
    ==> elems()                           # 计算个数
    ==> say;                              # 输出结果

## 运行时间：5.2s

注意使用了`Z`操作符和+来压缩 `0,@p` 和 `@p,0` 的两个列表。

这个单行生成杨辉三角的写法是从[Rosetta代码](http://rosettacode.org/wiki/Pascal%27s_triangle#Perl_6)里偷过来的。那是另一个不错的项目，如果你对 Perl6 的片段练习很感兴趣的话。

让我们做些更巧妙的：

# 问题9

    There exists exactly one Pythagorean triplet for which a + b + c = 1000. Find the product abc.

Using brute force [will work](https://github.com/perl6/perl6-examples/blob/master/euler/prob009-polettix.pl) (solution courtesy of Polettix), but it won’t be fast (~11s on my machine). Therefore, we’ll use a bit of algebra to make the problem more managable:

Let (a, b, c) be a Pythagorean triplet

    a < b < c
    a² + b² = c²
For N = a + b + c it follows

    b = N·(N - 2a) / 2·(N - a)
    c = N·(N - 2a) / 2·(N - a) + a²/(N - a)
which automatically meets b < c.

The condition a < b gives the constraint

    a < (1 - 1/√2)·N
We arrive at

    sub triplets(\N) {
        for 1..Int((1 - sqrt(0.5)) * N) -> \a {
            my \u = N * (N - 2 * a);
            my \v = 2 * (N - a);

            # check if b = u/v is an integer
            # if so, we've found a triplet
            if u %% v {
                my \b = u div v;
                my \c = N - a - b;
                take $(a, b, c);
            }
        }
    }

    say [*] .list for gather triplets(1000);

## 运行时间：0.5s

Note the declaration of sigilless variables \N, \a, …, how $(…) is used to return the triplet as a single item and .list – a shorthand for `$_.list` – to restore listy-ness.

The sub &triplets acts as a generator and uses &take to yield the results. The corresponding &gather is used to delimit the (dynamic) scope of the generator, and it could as well be put into &triplets, which would end up returning a lazy list.

We can also rewrite the algorithm into dataflow-driven style using feed operators:

    constant N = 1000;

    1..Int((1 - sqrt(0.5)) * N)
    ==> map -> \a { [ a, N * (N - 2 * a), 2 * (N - a) ] }
    ==> grep -> [ \a, \u, \v ] { u %% v }
    ==> map -> [ \a, \u, \v ] {
        my \b = u div v;
        my \c = N - a - b;
        a * b * c
    }
    ==> say;

## 运行时间：0.5s

Note how we use destructuring signature binding -> […] to unpack the arrays that get passed around.

There’s no practical benefit to use this particular style right now: In fact, it can easily hurt performance, and we’ll see an example for that later.

It is a great way to write down purely functional algorithms, though, which in principle would allow a sufficiently advanced optimizer to go wild (think of auto-vectorization and -threading). However, Rakudo has not yet reached that level of sophistication.

But what to do if we’re not smart enough to find a clever solution?

# Problem 47

    Find the first four consecutive integers to have four distinct prime factors. What is the first of these numbers?

This is a problem where I failed to come up with anything better than brute force:

    constant $N = 4;

    my $i = 0;
    for 2..* {
        $i = factors($_) == $N ?? $i + 1 !! 0;
        if $i == $N {
            say $_ - $N + 1;
            last;
        }
    }

Here, &factors returns the number of prime factors. A naive implementations looks like this:

    sub factors($n is copy) {
        my $i = 0;
        for 2, 3, *+2 ...^ * > $n {
            if $n %% $_ {
                ++$i;
                repeat while $n %% $_ {
                    $n div= $_
                }
            }
        }
        return $i;
    }

## 运行时间：unknown (33s for N=3)

Note the use of repeat while … {…}, the new way to spell do {…} while(…);.

We can improve this by adding a bit of caching:

    BEGIN my %cache = 1 => 0;

    multi factors($n where %cache) { %cache{$n} }
    multi factors($n) {
        for 2, 3, *+2 ...^ * > sqrt($n) {
            if $n %% $_ {
                my $r = $n;
                $r div= $_ while $r %% $_;
                return %cache{$n} = 1 + factors($r);
            }
        }
        return %cache{$n} = 1;
    }

## 运行时间：unknown (3.5s for N=3)

Note the use of BEGIN to initialize the cache first, regardless of the placement of the statement within the source file, and multi to enable multiple dispatch for &factors. The where clause allows dynamic dispatch based on argument value.

Even with caching, we’re still unable to answer the original question in a reasonable amount of time. So what do we do now? We cheat and use [Zavolaj](https://github.com/jnthn/zavolaj) – Rakudo’s version of NativeCall – to [implement the factorization in C](https://github.com/perl6/perl6-examples/blob/master/euler/prob047-gerdr.c).

It turns out that’s still not good enough, so we refactor the remaining Perl code and add some native type annotations:

    use NativeCall;

    sub factors(int $n) returns int is native('./prob047-gerdr') { * }

    my int $N = 4;

    my int $n = 2;
    my int $i = 0;

    while $i != $N {
        $i = factors($n) == $N ?? $i + 1 !! 0;
        $n = $n + 1;
    }

    say $n - $N;

## 运行时间：1m2s (0.8s for N=3)

For comparison, when implementing the algorithm completely in C, the runtime drops to under 0.1s, so Rakudo won’t win any speed contests just yet.

As an encore, three ways to do one thing:

# Problem 29

    How many distinct terms are in the sequence generated by ab for 2 ≤ a ≤ 100 and 2 ≤ b ≤ 100?

A beautiful but slow solution to the problem can be used to verify that the other solutions work correctly:

    say +(2..100 X=> 2..100).classify({ .key ** .value });

## 运行时间：11s

Note the use of X=> to construct the cartesian product with the pair constructor => to prevent flattening.

Because Rakudo supports big integer semantics, there’s no loss of precision when computing large numbers like 100100.

However, we do not actually care about the power’s value, but can use base and exponent to uniquely identify the power. We need to take care as bases can themselves be powers of already seen values:

    constant A = 100;
    constant B = 100;

    my (%powers, %count);

    # find bases which are powers of a preceeding root base
    # store decomposition into base and exponent relative to root
    for 2..Int(sqrt A) -> \a {
        next if a ~~ %powers;
        %powers{a, a**2, a**3 ...^ * > A} = a X=> 1..*;
    }

    # count duplicates
    for %powers.values -> \p {
        for 2..B -> \e {
            # raise to power \e
            # classify by root and relative exponent
            ++%count{p.key => p.value * e}
        }
    }

    # add +%count as one of the duplicates needs to be kept
    say (A - 1) * (B - 1) + %count - [+] %count.values;

## 运行时间：0.9s

Note that the sequence operator ...^ infers geometric sequences if at least three elements are provided and that list assignment %powers{…} = … works with an infinite right-hand side.

Again, we can do the same thing in a dataflow-driven, purely-functional fashion:

    sub cross(@a, @b) { @a X @b }
    sub dups(@a) { @a - @a.uniq }

    constant A = 100;
    constant B = 100;

    2..Int(sqrt A)
    ==> map -> \a { (a, a**2, a**3 ...^ * > A) Z=> (a X 1..*).tree }
    ==> reverse()
    ==> hash()
    ==> values()
    ==> cross(2..B)
    ==> map -> \n, [\r, \e] { (r) => e * n }
    ==> dups()
    ==> ((A - 1) * (B - 1) - *)()
    ==> say();

## 运行时间：1.5s

Note how we use &tree to prevent flattening. We could have gone with X=> instead of X as before, but it would make destructuring via -> \n, [\r, \e] more complicated.

As expected, this solution doesn’t perform as well as the imperative one. I’ll leave it as an exercise to the reader to figure out how it works exactly ;)

# That’s it

Feel free to add your own solutions to the [Perl6 examples repository](https://github.com/perl6/perl6-examples) under [euler/](https://github.com/perl6/perl6-examples/tree/master/euler).

If you’re interested in bioinformatics, you should take a look at [Rosalind](http://rosalind.info/) as well, which also has its own (currently only sparsely populated) examples directory [rosalind/](https://github.com/perl6/perl6-examples/tree/master/rosalind).

Last but not least, some solutions for the [Computer Language Benchmarks Game](http://shootout.alioth.debian.org/) – also known as the Debian language shootout – can be found under [shootout/](https://github.com/perl6/perl6-examples/tree/master/shootout/).

You can contribute by sending pull requests, or better yet, join #perl6 on the Freenode IRC network and ask for a commit bit.

_Have the appropriate amount of fun!_
