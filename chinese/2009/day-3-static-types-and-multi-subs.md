打开Advent 这第三个盒子,这次我们要读到什么啦？啊….真好.这次没想到有二个礼物.这个盒子中放着 static types 和 multi subs.

在 Perl 5 中,$scalar 的标量只能包含二种东西引用或值,这值可以是任何东西,能是整数,字符,数字,日期和你的名字.这通常是非常方便的,但并不明确.
在 Perl6 中给你机会修改标量的类型 .如果你这个值比较特别,你可以直接放个类型名在 my 和 $variable 的中间.象下面的例子,是在设置値一定要是一个 Int 型的数据,来节约 cpu 判断类型的时间,和让你更少的程序上出错.

```
my Int $days = 24;
```

其它的标量类型如下：

```
my Str $phrase = "Hello World";
my Num $pi = 3.141e0;
my Rat $other_pi = 22/7;
```

如果你还是想用老的设置值的方法,你可以不声明类型或使用 Any 的类型代替.
 

今天盒子中的第二个礼物 multi subs 也很容易,因为我们会手把手教你.到底什么是 multi subs ? 简单的来讲 multi subs 可以让我们重载 sub 的名字.当然 Multi subs 可以做更多其它的事情,所以下次其它作者的礼物中也会有这个,但现在我们会先介绍几个非常有用的一些 sub .

```
multi sub identify(Int $x) {
    return "$x is an integer.";
}
 
multi sub identify(Str $x) {
    return qq<"$x" is a string.>;
}
 
multi sub identify(Int $x, Str $y) {
    return "You have an integer $x, and a string \"$y\".";
}
 
multi sub identify(Str $x, Int $y) {
    return "You have a string \"$x\", and an integer $y.";
}
 
multi sub identify(Int $x, Int $y) {
    return "You have two integers $x and $y.";
}
 
multi sub identify(Str $x, Str $y) {
    return "You have two strings \"$x\" and \"$y\".";
}
 
say identify(42);
say identify("This rules!");
say identify(42, "This rules!");
say identify("This rules!", 42);
say identify("This rules!", "I agree!");
say identify(42, 24);
```

还有两个礼物很有优势吧.你可以尝试多使用他们,我们会不断的丰富这个 Advent 的树,并不断放更多的礼物,希望你能多来看看.
