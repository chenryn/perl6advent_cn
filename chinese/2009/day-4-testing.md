Perl 的作者都有非常好的传统,就是会对自己写的模块进行完整的测试.在 Perl 6 中我们打算延续这个良好的传统.
测试是非常容易的,传统的测试方法是打印所有协议的数据出来,但是你没有必要这样做,因为我们都使用模块来实成.
假设你写了一个非常好的阶乘的功能函数

```
sub fac(Int $n) {
    [*] 1..$n
}
```

通常我们没有必要关心子函数内部是怎么工作的.,我们想看看是否合适我们使用,因此,我们测试一下它.

```
use v6;
 
sub fac(Int $n) {
    [*] 1..$n
}
 
use Test;
plan 6;
 
is fac(0), 1,  'fac(0) works';
is fac(1), 1,  'fac(1) works';
is fac(2), 2,  'fac(2) works';
is fac(3), 6,  'fac(3) works';
is fac(4), 24, 'fac(4) works';
 
dies_ok { fac('oh noes i am a string') }, 'Can only call it with ints';
```

现在让我们来运行这个

```
$ perl6 fac-test.pl
1..6
ok 1 - fac(0) works
ok 2 - fac(1) works
ok 3 - fac(2) works
ok 4 - fac(3) works
ok 5 - fac(4) works
ok 6 - Can only call it with ints
```

讲解: use Test 加载 test 的模块, plan 6; 声明一下,我们要运行6次这个测试. 接下来的 5 行是 $got, $expected, $description, is() 是用来做字符串对比的, 当然整数也可以使用这个方式在 Perl 中一直如此.最后用 dies_ok { $some_code }, $description 来测试这个功能传送进去不是整数时出错时的特性
这个输出包含计划的 1 .. 6 测试.接下来是每行的内容中,开始的部分显示的是 ok(如果不是 ok 就是测试失败了).接下来是测的数量,空格,破折号,空格,测试描述.


如果你运行了更加多的测试,你可能不想让大家要看到每个详细测试的结果,因为那样很长,但是你想让大家见到概要,你可以让它显示一些象 Perl5 中的概要出来.

```
$ prove --exec perl6 fac-test.pl
fac-test.pl .. ok
All tests successful.
Files=1, Tests=6, 11 wallclock secs ( 0.02 usr 0.00 sys + 10.26 cusr 0.17 csys = 10.45 CPU)
Result: PASS
```

你也能在你的测试文件的目录中,自动让它测试 t/ 下,然后检验这个目录下面全部的 .t 的文件.

```
$ prove --exec perl6 -r t
```

最佳方案是放上面这行到你的 Makefile 中.这样,你就能使用 make test 来运行上面的测试了.
