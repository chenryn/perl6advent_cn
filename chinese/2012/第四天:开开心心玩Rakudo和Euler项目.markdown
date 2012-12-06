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
    存在一个毕达哥拉斯三元数组让 `a +b + c = 1000` 。求a、b、c的值。

暴力破解[可以完成](https://github.com/perl6/perl6-examples/blob/master/euler/prob009-polettix.pl) (Polettix 的解决办法)，但是这个办法不够快（在我机器上花了11秒左右）。让我们用点代数知识把问题更简单的解决。

先创建一个 (a, b, c) 组成的毕达哥拉斯三元数组

    a < b < c
    a² + b² = c²

要求 N = a + b +c 就要符合：

    b = N·(N - 2a) / 2·(N - a)
    c = N·(N - 2a) / 2·(N - a) + a²/(N - a)

这就自动符合了 b < c 的条件。

而 a < b 的条件则产生下面这个约束：

    a < (1 - 1/√2)·N

我们就得到以下代码了：

    sub triplets(\N) {
        for 1..Int((1 - sqrt(0.5)) * N) -> \a {
            my \u = N * (N - 2 * a);
            my \v = 2 * (N - a);

            # 检查 b = u/v 是否是整数
            # 如果是，我们就找到了一个三元数组
            if u %% v {
                my \b = u div v;
                my \c = N - a - b;
                take $(a, b, c);
            }
        }
    }

    say [*] .list for gather triplets(1000);

## 运行时间：0.5s

注意 sigilless (译者注：实在不知道这个怎么翻译)变量`\N`，`\a`……的声明，`$(...)`是怎么用来把三元数组作为单独元素返回的，用`$_.list`的缩写`.list`来恢复其列表性。

`&triplets` 子例程作为生成器，并且使用 `&take` 切换到结果。相应的 `&gather` 用来划定生成器的(动态)作用域，而且它也可以放进 `&triplets`，这个可能返回一个懒惰列表。

我们同样可以使用流操作符改写成数据流驱动的风格：

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

注意我们是怎样用解压签名绑定 `-> [...]` 来解压传递过来的数组的。

使用这种特殊的风格没有什么实质的好处：事实上还很容易影响到性能，我们随后会看到一个这方面的例子。

写纯函数式算法是个超级好的路子。不过原则上这就意味着让那些足够先进的优化器乱来（想想自动向量化和线程）。不过Rakudo还没到这个复杂地步。

但是如果我们没有聪明到可以找到这么牛叉的解决办法，该怎么办呢？

# 问题47

    求第一个连续四个整数，他们有四个不同的素因数。

除了暴力破解，我没找到任何更好的办法：

    constant $N = 4;

    my $i = 0;
    for 2..* {
        $i = factors($_) == $N ?? $i + 1 !! 0;
        if $i == $N {
            say $_ - $N + 1;
            last;
        }
    }

这里，`&fators` 返回素因数的个数，原始的实现差不多是这样的：

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

注意 `repeat while ...{...}` 的用法, 这是`do {...} while(...);`的新写法。

我们可以加上点缓存来加速程序：

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

注意用 `BEGIN` 来初始化缓存，不管出现在源代码里哪个位置。还有用 `multi` 来启用对 `&factors` 的多样调度。`where` 子句可以根据参数的值进行动态调度。

哪怕有缓存，我们依然无法在一个合理的时间内回答上来原来的问题。现在我们怎么办？只能用点骗子手段了[Zavolaj](https://github.com/jnthn/zavolaj) – Rakudo版本的NativeCall – 来[在C语言里实现因式分解](https://github.com/perl6/perl6-examples/blob/master/euler/prob047-gerdr.c).

事实证明这还不够好，所以我们继续重构剩下的代码，添加一些原型声明：

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

相比之下，完全使用C语言实现这个算法，运行时间在0.1秒之内。所以目前Rakudo还没法赢得任何一种速度测试。

重复一下，用三种办法做一件事：

# 问题29

    在 2 ≤ a ≤ 100 和 2 ≤ b ≤ 100 的情况下由a<sup>b</sup>生成的序列里有多少不一样的元素？

下面是一个很漂亮但很慢的解决办法，可以用来验证其他办法是否正确：

    say +(2..100 X=> 2..100).classify({ .key ** .value });

## 运行时间：11s

注意使用 `X=>` 来构造笛卡尔乘积。用对构造器 `=>` 防止序列被压扁而已。

因为Rakudo支持大整数语义，所以在计算像100100这种大数的时候没有精密度上的损失。

不过我们并不真的在意幂的值，不过用基数和指数来唯一标示幂。我们需要注意基数可能自己本身就是前面某次的幂值：

    constant A = 100;
    constant B = 100;

    my (%powers, %count);

    # 找出那些是之前基数的幂的基数
    # 分别存储基数和指数
    for 2..Int(sqrt A) -> \a {
        next if a ~~ %powers;
        %powers{a, a**2, a**3 ...^ * > A} = a X=> 1..*;
    }

    # 计算重复的个数
    for %powers.values -> \p {
        for 2..B -> \e {
            # 上升到 \e 的幂
            # 根据之前的基数和对应指数分类
            ++%count{p.key => p.value * e}
        }
    }

    # 添加 +%count 作为一个需要保存的副本
    say (A - 1) * (B - 1) + %count - [+] %count.values;

## 运行时间：0.9s

注意用序列操作符 `...^` 推断集合序列，只要提供至少三个元素，列表赋值 `%powers{...} = ...` 就会无休止的进行下去。

我们再次用数据驱动的函数式的风格重写一遍：

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

注意我们怎么用 `&tree` 来防止压扁的。我们可以像之前那样用 `X=>` 替代 `X` ，不过这会让通过 `->  \n, [\r, \e]` 解构变得很复杂。

和预想的一样，这个写法没像命令式的那样执行出来。怎么才能正常运行呢？这算是我留给读者的作业吧。

# 最后

欢迎添加你自己的解决办法到[euler/](https://github.com/perl6/perl6-examples/tree/master/euler)下的[Perl6 examples repository](https://github.com/perl6/perl6-examples)。

如果你对生物信息学感兴趣，你也可以看看[Rosalind](http://rosalind.info/)，Perl6 也有自己的示例库（只不过目前代码不多）[rosalind/](https://github.com/perl6/perl6-examples/tree/master/rosalind)。

最后但不是最新的，[计算机语言测试游戏](http://shootout.alioth.debian.org/) - 又叫 Debian 语言枪战 - 的解决办法可以在[shootout/](https://github.com/perl6/perl6-examples/tree/master/shootout/)下找到。

You can contribute by sending pull requests, or better yet, join #perl6 on the Freenode IRC network and ask for a commit bit.
你可以通过发送pull请求做贡献，或者更好的办法是加入 Freenode IRC 网络的 #perl6 频道要 commit 权限。

_好好享受吧！_
