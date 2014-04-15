我们以前 advent 了解过的内容,对于今天所要介绍的礼物非常有用,今天要讲二个东西： comb 的方法和 constraints 的概念
constraints 和原来那章节中提到的静态变量定义的相同,constraints 可以让我们在写程序的时候就更方便的在子函数和方法上进行控制.在很多其它的程序中,你可以通过参数调用子函数并可以在参数进入的时候就通过 constraints 来验证输入的内容.这样我们就能在程序声明的时候就验证输入的内容,不在需要等到程序运行的时候.
下面是一个基本的例子,如果是一个整数和偶数,在子函数中它会不能处理下去.在 Perl 5 中的实际基本就象下面这样子了：

```
sub very_odd
{
    my $odd = shift;
    unless ($odd % 2)
    {
        return undef;
    }
    # 在这接着处理奇数.
}
```

在 Perl 6 中,我们可以只需要简单的：

```
sub very_odd(Int $odd where {$odd % 2})
{
    # 在这接着处理奇数.
}
```

如果你试图来传入一个偶数来调用 very_odd.你会直接得到一个 error.不要担心：你可以使用 multi sub 的功能来给偶数一个机会…:)

```
multi sub very_odd(Int $odd where {$odd % 2})
{
    # Process the odd number here
}
multi sub very_odd(Int $odd) { return Bool::False; }
```

我们在使用成对的 .comb 方法时,这个 constraints 是非常有用.为什么正好是 .comb ?
当我们早上梳整我们的头发时,我们先通常使用梳子来梳成你想要的样子(线条),然后在你的头上固定梳成的样子.前面讲的内容在这非常象.split.在这也一样,你不是真想要切开字符串,而是你想达到一个什么样目的.这一段简单的代码,来说明这二种目标：

```
>say "Perl 6 Advent".comb(/<alpha>/).join('|');
P|e|r|l|A|d|v|e|n|t
>say "Perl 6 Advent".comb(/<alpha>+/).join('|');
Perl|Advent
```

正则表达式有可能另一天会拿出来讲,但是我们先快速了解一下是没有坏处的.这个第一行,会输出 P|e|r|l|A|d|v|e|n|t.它会取得每个字母然后放到一个暂时的数组中,然后使用 join 管道连接起来这是目的.第二行也有点象,但它捕获了更多的字母,会输出 Perl|Advent 这是第二个的目标单词.
这个 .comb 是非常非常强大,然而,你得到你梳出来的输出,你就能操作这个串了如果你有一个基本的ASCII十六进制字符的字符串,可以使用的 hyperoperators 超的操作符转变各自的块成为等效的 ASCII 字符！

```
say "5065726C36".comb(/<xdigit>**2/)».fmt("0x%s")».chr
# Outputs "Perl6"
```

如果你提心这个,你可以使用 .map 的方法：

```
say "5065726C36".comb(/<xdigit>**2/).map: { chr '0x' ~ $_ } ;
#Outputs "Perl6"
```

记的,这是 Perl.做任何事情都不只一种方法.
今天给完了所有礼物,我现在向你挑战.有 KyleHasselbacher 的协助,我们能使用约束.comb 和 .map 做出一个像样的版本的古老的凯撒加密法.

```
use v6;
 
sub rotate_one( Str $c where { $c.chars == 1 }, Int $n ) {
    return $c if $c !~~ /<alpha>/;
    my $out = $c.ord + $n;
    $out -= 26 if $out > ($c eq $c.uc ?? 'Z'.ord !! 'z'.ord);
    return $out.chr;
}
 
sub rotate(Str $s where {$s.chars}, Int $n = 3)
{
    return ($s.comb.map: { rotate_one( $_, $n % 26 ) }).join( '' );
}
 
die "Usage:\n$*PROGRAM_NAME string number_for_rotations" unless @*ARGS == 2;
 
my Str $mess = @*ARGS[0];
my Int $rotate = @*ARGS[1].Int;
 
say qq|"$mess" rotated $rotate characters gives "{rotate($mess,$rotate)}".|;
``` 

我希望你在休息的时候,可以使用目前为止在 Perl 6 中和今天的礼物中的学到的内容来编写编码算法.毕竟,编程语言本身只有更多的使用,才能让它变的更优秀.
