当我们回过头来看2009年的Perl6圣临月历，那时候只有Rakudo一个项目孤零零的在Perl6的世界里。但Perl6从一开始的目的，就是成为一个可以多种
实现的编程语言。到目前已经有了四种不同的Perl6实现。当然，我这里没法一一介绍他们，只是相应的给出他们的超链接。

最稳定和完整的实现是Rakudo
Star。这基于Rakudo的最后一次重大修订（七月后暂时冻结了）。目前Rakudo开发稍微落后于Perl6。她运行也比较慢，不过最重要的，她非常可靠！

目前Rakudo的开发版本名叫"Nom"。比起稳定版的Star，Nom大大提升了性能，还提供了原生的类型(type)和一个更好的元模型(metamodel)
。比如你试试看Grammar::Tracer模块，这里面利用新的元模型，仅仅用了44行代码就添加了正则表达式追踪的功能。当然现在还不是启用Nom的黄金时间，
还有一些Star里已有的特性尚未支持。不过开发进展是难以置信的快，估计这个月就能看到基于Nom的新版Rakudo Star发布出来了！

Stanfan O'Rear的[Niecza](https://github.com/sorear/niecza)项目在去年的这个时候还刚刚起步，但现在它已
经成为Rakudo最严重的竞争者。Niecza构建在CLR(.NET和Mono)上，已经实现了Perl6的重要部分，并且可以轻松的在现有的CLR库上运行。

最后，ingy和Masak计划重启Pugs项目，这是最早用Haskell实现的Perl6。到现在为止，他们刚刚完成在最新版Haskell编译器上重新构建Pu
gs。长期的目标，则是让Pugs项目再次运行通过测试并接近目前的新版Perl6规范。

那么你应该用哪一种？如果你要找的是一个稳定的，完整实现的Perl6，那选Rakudo Star。如果你是想自己探索一下Perl6语言，那么试试Rakudo 
Nom，你可能会碰上bug，但是Nom比Star先进多了，而且报告bug对Rakudo的开发也是很有帮助的。如果你是想利用CLR库，那么Niecza再好不过
了。这里有一个方便的[特性对比图](http://perl6.org/compilers/features)。

就我个人而言，这三种我都安了，并且跑了不同的项目在上面。

最后，遇到问题不要犹豫，尽管在这里留言或者上Freenode的IRC频道#perl6发问，Perl6社区绝对是友好的。

