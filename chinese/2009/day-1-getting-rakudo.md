Perl6 有各种各样的不同的实现.现在完成得最好的就是 Rakudo.我们也有好几种方法来取得这个和运行这个.如果你有兴趣帮着开发,最好直接下载源代码.

如果你想下载和安装我们的最新开发的 Rakudo,需要安装 git ,还有 Perl 5.8 , C 编译器, make 工具.编译需要在标准的类 Linux 系统上(包括OS X).

编译方法：

```
$ git clone git://github.com/rakudo/rakudo.git
$ cd rakudo
$ perl Configure.pl --gen-parrot
$ make
$ make test
$ make install
```

这实际上是在次调用 svn or git 接着取得合适的 Parrot 才能编译它.你必须使用你系统中合适的 make 命令来编译(在 windows 上应该是带有 MS Visual C++ 的 nmake)。

当前的 Rakudo 在 make install 后,并不会放到你的 $PATH 环境变量中,只是放到你系统的 install 目录中,所以你想在你的系统中任何目录中都能运行 Perl6 的执行文件,你可以很简单的使用 Perl6 ,可以不加参数.不加参数就直接进入了 Perl 的 [REPL](http://en.wikipedia.org/wiki/Read-eval-print_loop) 环境，你可以直接在这个环境中输入命令并直接看到输出。这样会非常方便你来测试 Perl6 的一些功能

```
$ ./perl6
> say "Hello world!";
Hello world!
> say (10/7).WHAT
Rat()
> say [+] (1..999).grep( { $_ % 3 == 0 || $_ % 5 == 0 } );
233168
```

当你在 $ 后面见到 > 时.你就进入了 Rakudo 的环境中,可以执行一些东西见到 Rakudo 的响应.第一个例子是一个简单的 say 声明.第二个是建了一个数和检查它的类型.可以见到是 Rat (有理数).这第三个取得的数字是从 1 到 999 之间,然后过滤能整除 3 和 5 的数进行汇总并打印结果.这是一个欧拉项目的第一个练习题（[Project Euler](http://projecteuler.net/)）感谢 [draegtun](http://transfixedbutnotdead.com/2009/11/30/eulergy/) 提醒我.这几个例子我们可以用来理解 Perl6 的特性怎么在这上面工作的.

最后一件事,如果你使用 Rakudo 时出了任何问题,在 irc.freenode.net 上的 #perl6 的频道对你会非常有帮助的.

译注1：Project Euler 是一个具有挑战性的不仅仅需要具备数学能力的“数学/计算机编程”问题集合.数学方面的知识可以帮助你获得优雅而高效的解决方案,与此同时,计算机应用和编程技巧也不可或缺.

译注2：Project Euler 第二个练习题是斐波那契数列,也提供一个 Perl6 实现的版本,很取巧 my @fib := 1, 1, *+* …^ * >= 100; 但不如上面的可读性…

译注3：现在建议使用：

```
$ perl Configure.pl --gen-moar --gen-nqp --backends=moar
```

来生成MoarVM上的Perl6而不是Parrot上的。
上面的参数 --gen-moar 实际上是在调用 svn 或 git 生成合适的 MoarVM 的编译文件并编译它，MoarVM 是 Perl6 中最建议使用的 Perl6 的 Virtual Machine，也就是说， Perl 程序将在 MoarVM 上执行，程序所面对的是个共通的跨平台 Virtual Machine 环境，而不用考虑您所面对的 OS 环境，就像 Java、.NET 所使用的 VM 一样。参数-gen-nqp 会下载一份 NQP，NQP 是一个小型的 Perl6 编译器，用来构建 Rakudo，Rakudo 是用于 MoarVM 虚拟机上的编译器。
