## 2010 年 Perl6 圣诞月历(二十) Perl6 的提要

这个博客的主线就是每天一篇 perl6 的酷毙了的特性。今天，我就来说说我认为非常非常酷的一个东西 —— 提要。

首先，快速的过一下背景资料。当 2000 年 Perl6 第一次被喊出来的时候，社区其实并不知道要做什么。于是 RFC 征集活动开始了，最后收到了 360+份 关于 perl 的提议。Larry Wall 从中整理出来了 Perl6 的设计启示录。后来，Damian Conway 加上了关于如果设计以便实践的注释。。。

快进到当前。现在已经有了好几个 Perl6 的实现，分别关注于不同的目标。一个优先考虑面向对象的模型，一个考虑快速的解析引擎，一个考虑优先实现所有的 Perl6 语法。他们是怎么在自己特定的范围内保持着 Perl6 的特性呢？

答案就是[提要](http://perlcabal.org/syn/)！这些文档是 Perl6 的官方规范。每一个提要都涵盖了 Perl6 语言的某个特定主题。就像《 Perl 编程》里的章节一样。

当你在运行某个实现的时候觉得似乎自己找到了一个 bug，怎么确定这是一个 bug 呢？参考相关的提要就好了。perl6 社区总是首先保证提要的明确性的。

如果你认为这是提要的 bug，或者它跟另一个提要有冲突了，那么发信到 perl6-language@perl.org 或者上 #perl6:irc.freenode.net 频道讨论一下。那里有很多关于提要的有趣的东东。这就像活字典一样可爱~如果有矛盾，或者只是需要澄清的地方，在 #perl6 频道里说说，一般都能解决。其实，你只要在一些公共的地方，比如论坛，微博（译者注：好吧，是 twitter……）说起来你碰到的麻烦，都会获得足够的重视的。我们这可没有层层的官僚机构拖延的可能。

