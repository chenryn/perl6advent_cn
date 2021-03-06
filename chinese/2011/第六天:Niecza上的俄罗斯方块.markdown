[Niecza](https://github.com/sorear/niecza)是另一个在Mono和.NET平台上的Perl6实现，现在他已经可以调用几
乎所有的CLR库文件。在Niecza的示例目录里，有一个简单的30行代码的gtk1.pl用来演示怎么使用gtk-
sharp和Gnome的图形化基础库Gtk/Gdk。下面是脚本最中心的工作部分：

    
    my $btn = Button.new("Hello World");
    $btn.add_Clicked: sub ($obj, $args) {
        # 在按键被点击的时候运行
        say "Hello World";
        Application.Quit;
    };

这个add_Clicked方法定义了一个回调例程，用来处理用户的输入。运行gtk1.pl会在窗口中得到一个大小改变了的按钮，然后关闭掉。

![](http://perl6advent.files.wordpress.com/2011/12/helloworld.png)

从这个gtk1到俄罗斯方块已经不远了。[源代码](https://github.com/sorear/niecza/blob/master/examples
/gtk-tetris.pl)也在示例目录里。只需要加上两个额外的部分就可以做到：一个定时器来回调例程控制下落的方块，一个非阻塞的键盘输入给用户提供控制感。
加上一些简单的物理或者Cairo的图像你就可以搞定这个颇具可玩性的游戏啦，这一切，只需要170行Perl6代码！

定时器的动画控制，是通过ExposeEvent定时重绘整个窗口来完成的。重绘操作试图将方块向下移动，如果物学告诉我们说不能再移了，那就在顶上重新加上一个方块
。（这里有个Bug：当方块已经满屏的时候会失败）GlibTimeout用来设置调用了.QueueDraw方法的定时器回调处理。默认间隔是300毫秒，如果游戏
引擎想要加速，只需要调整$newInterval，在下一次调用GlibTimeout的时候就改过来了。

    
    my $oldInterval = 300;
    my $newInterval = 300;
    ...
    GLibTimeout.Add($newInterval, &TimeoutEvent;);
    ...
    sub TimeoutEvent()
    {
        $drawingarea.QueueDraw;
        my $intervalSame = ($newInterval == $oldInterval);
        unless $intervalSame { GLibTimeout.Add($newInterval, &TimeoutEvent;); }
        return $intervalSame; # 返回真表示继续调用这个超时处理
    }
    

感谢Gtk处理输入的优秀方式，每一次按键事件都是自我记录的。Piece子例程这么做物理运算（$colorindex 4是不旋转的正方块）：

    
    $drawingarea.add_KeyPressEvent(&KeyPressEvent;);
    ...
    sub KeyPressEvent($sender, $eventargs) #OK not used
    {
        given $eventargs.Event.Key {
            when 'Up' { if $colorindex != 4 { TryRotatePiece() } }
            when 'Down' { while CanMovePiece(0,1) {++$pieceY;} }
            when 'Left' { if CanMovePiece(-1,0) {--$pieceX;} }
            when 'Right' { if CanMovePiece( 1,0) {++$pieceX;} }
        }
        return True; # 表示按键动作已经处理了
    }
    

再补充一点胶水粘合，最终结果就出来了：

![](http://perl6advent.files.wordpress.com/2011/12/tetris.png)

本文没有涉及比如图形绘制等其他细节，因为这些内容会在圣临月历里慢慢讲述，甚至包括有更漂亮的不规则图案！所以好好期待吧。另：以上内容在[2011年伦敦Perl
研讨会](http://conferences.yapceurope.org/lpw2011/)上[介绍](http://conferences.yapce
urope.org/lpw2011/talk/3893)过了。

