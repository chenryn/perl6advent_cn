今天我就不分享那些特性和妙用了，简单的说说给Perl6项目做点有用的贡献的办法吧。下面我带你走一遍给Niecza项目做修改的流程。这可能需要一点点相关领域的
知识（相信#perl6频道上的父老乡亲们会很乐于帮你的），但绝对用不上航天科学，甚至大多数时候连高深一点的计算机科学水平都不用。

几天前，Radvendi在#perl6频道里问："Perl6核心里有没有提供round函数啊？"正确答案是："这个可以有！"于是这个问题导致了Rakudo项
目好几个bug的修复。但这件事情让我考虑更多的问题----
Niecza项目正确支持了round函数（以及相关的ceiling/floor/truncate函数）么？

Perl6有一个庞大的测试套件，用来判定一个Perl6实现是否符合Perl规范，这里面有一个文件就是做round测试的，即S32-num/rounders.
t。我的第一步，就是去检查Niecza是否可以运行这个测试。跟Rakudo一样，测试数据存在t/spectest.data里：

    
    
    Wynne:niecza colomon$ grep round t/spectest.data
    Wynne:niecza colomon$
    

嘿嘿，这显然是因为我们还没运行S32-num/rounders.t测试啦。（注意，如果你听着越来越茫然了，注意本文链接指向的是这个文件的最新地址，包含了我写
的这篇文章的所有变动）这就是有些东西没有被正确支持的标示。所以现在让我们运行一下看看究竟吧~Niecza和Rakudo都使用了一个"虚假"的进程，用来在特定
的编译器里运行代码，以便在不正常运行的地方做上标记。现在就让我们用这个"虚假"工具试试：

    
    
    Wynne:niecza colomon$ t/fudgeandrun t/spec/S32-num/rounders.t
    1..108
    not ok 1 - floor(NaN) is NaN
    # /Users/colomon/tools/niecza/t/spec/S32-num/rounders.t line 16
    #    Failed test
    #           got: -269653970229347386159395778618353710042696546841345985910145121736599013708251444699062715983611304031680170819807090036488184653221624933739271145959211186566651840137298227914453329401869141179179624428127508653257226023513694322210869665811240855745025766026879447359920868907719574457253034494436336205824
    

接着是15个类似的错误，然后：

    
    
    Unhandled exception: Unable to resolve method truncate in class Num
      at /Users/colomon/tools/niecza/t/spec/S32-num/rounders.t line 34 (mainline @ 32)
      at /Users/colomon/tools/niecza/lib/CORE.setting line 2224 (ANON @ 2)
      at /Users/colomon/tools/niecza/lib/CORE.setting line 2225 (module-CORE @ 58)
      at /Users/colomon/tools/niecza/lib/CORE.setting line 2225 (mainline @ 1)
      at  line 0 (ExitRunloop @ 0)
    

好了，至少有两个错误需要修正。

我们将按照这个顺序，慢慢修复，哪怕这往往意味着第一个错误就是最难办的...（如果你觉得这部分太难了，可以跳过，以为最后一部分改进真的是令人难以置信的简单）打
开src/CORE.setting文件，找到关于round的定义：

    
    
    sub round($x, $scale=1) { floor($x / $scale + 0.5) * $scale }
    

嗯，说明问题其实是在floor那：

    
    
    sub floor($x) { Q:CgOp { (floor {$x}) } }
    

这个怪怪的Q:CgOp是嘛玩意儿？嗯，它表示floor是用C#实现的。然后我们打开[lib/Builtins.cs](https://github.com/
sorear/niecza/blob/master/lib/Builtins.cs)文件查找floor，最终找到了这个"public static
Variable floor(Variable a1)"，这里代码很长，我就不全贴上来了，我们只关心这里的浮点数运算：

    
    
    if (r1 == NR_FLOAT) {
        double v1 = PromoteToFloat(r1, n1);
        ulong bits = (ulong)BitConverter.DoubleToInt64Bits(v1);
        BigInteger big = (bits & ((1UL << 52) - 1)) + (1UL << 52);
        int power = ((int)((bits >> 52) & 0x7FF)) - 0x433;
        // note: >>= has flooring semantics for signed values
        if ((bits & (1UL << 63)) != 0) big = -big;
        if (power > 0) big <<= power;
        else big >>= -power;
        return MakeInt(big);
    }
    

我们不需要知道怎么修复这个问题。关键点是PromoteToFloat这行，它设置v1为浮点数并最后输入给了我们的floor。我们在这后面加上一个trap，应
该就可以修复了。简单的网上搜索一下C#就知道，Double有几个函数IsNaN，IsNegativeInfinity和IsPositiveInfinity。
然后我们找找看，发现Niecza代码里有一个函数MakeFloat返回浮点数的，那我们试试好了：

    
    
    if (Double.IsNaN(v1) || Double.IsNegativeInfinity(v1) || Double.IsPositiveInfinity(v1)) {
        return MakeFloat(v1);
    }
    

然后make编译，重新运行测试文件：

    
    Wynne:niecza colomon$ t/fudgeandrun t/spec/S32-num/rounders.t
    1..108
    ok 1 - floor(NaN) is NaN
    ok 2 - round(NaN) is NaN
    ok 3 - ceiling(NaN) is NaN
    not ok 4 - truncate(NaN) is NaN
    # /Users/colomon/tools/niecza/t/spec/S32-num/rounders.t line 19
    #    Failed test
    #           got: -269653970229347386159395778618353710042696546841345985910145121736599013708251444699062715983611304031680170819807090036488184653221624933739271145959211186566651840137298227914453329401869141179179624428127508653257226023513694322210869665811240855745025766026879447359920868907719574457253034494436336205824
    

有进步！显然可以看到truncate是单独用了别的方法，我们也得另外修复这个了：

    
    
    sub truncate($x) { $x.Int }
    method Int() { Q:CgOp { (coerce_to_int {self}) } }
    
    
    
    public static Variable coerce_to_int(Variable a1) {
        int small; BigInteger big;
        return GetAsInteger(a1, out small, out big) ?
            MakeInt(big) : MakeInt(small);
    }
    

嗯，看起来比前面的复杂一点了，不过还是前面方法的基本变种。从附近的代码里找到了这样的样本：

    
    int r1;
    P6any o1 = a1.Fetch();
    P6any n1 = GetNumber(a1, o1, out r1);
     
    if (r1 == NR_FLOAT) {
        double v1 = PromoteToFloat(r1, n1);
        if (Double.IsNaN(v1) || Double.IsNegativeInfinity(v1) || Double.IsPositiveInfinity(v1)) {
            return MakeFloat(v1);
        }
    }
    

我跳过了代码里的HandleSpecial2，因为我一直没有确认这段代码到底是如何工作的。幸运的是，我们有spectests工具可以检测我这么做是不是有问题
。

现在rounders.t里的前面15个测试都通过了，只留下下面这么一行：

    
    
    Unhandled exception: Unable to resolve method truncate in class Num
    

这个处理起来很简单。让我们继续回去看lib/CORE.setting然后查找ceiling，然后我们可以看到它一共出现了两次：一次在基类Cool里，一次作为
独立的子例程。然后在这个子例程周围，我们看到floor/ceiling/round/truncate都是这里定义的。然后再看Cool里，却只定义了floor
/ceiling/round这几个，这就是问题的根源！
Cool里定义其他这些的方法都很简单；简单的转发到自己的子例程版本。所以我们可以添加truncate的代码如下：

    
    
    method truncate() { truncate self }
    

好，这次我们安全通过全部的108个测试了！

现在我们还剩下三件事情没有干。第一，既然rounders.t通过了，我们需要把他加进t/spectest.data里，这个列表是按次序排列的，我只需要找到S
21-num章节，然后依照字母排序添加S32-num/rouders.t就好了。 第二，我需要把这些更改提交到我的git项目副本里。（这个就不用解释了，网上
教程大把大把的）然后再运行一次spectest，确认这些更改不会影响到其他的代码出问题。（嘿嘿，事实上一些原本是TODO的条目也通过了，这个补丁还修复了其他
的bug。额，有一个挂了，不过这条在之前也只是意外成功过而已。现在再错也没什么大不了的。）

这些都完成后，你就需要提交补丁给Niecza开发者了，我想最简单的办法就是通过github了。

在我进行这些工作的时候，一个小想法突然撞进了我脑袋。目前的实现方法比较幼稚，floor把输入转换成浮点数（Perl6里的Num）然后执行Num.floor方
法。这种实现并不能对所有的数值有效。因为实际中，绝大多数的数值类型允许存储的数据量大小都比标准浮点数的要大！所以我们可能需要再测试的时候检查这种情况。现在让
我们加上这个。

rounders.t里的测试样本排列实在是和我的胃口，不过我们还是老老实实往最底下添加新测试好了。

    
    
    {
        my $big-int = 1234567890123456789012345678903;
        is $big-int.floor, $big-int, "floor passes bigints unchanged";
        is $big-int.ceiling, $big-int, "ceiling passes bigints unchanged";
        is $big-int.round, $big-int, "round passes bigints unchanged";
        is $big-int.truncate, $big-int, "truncate passes bigints unchanged";
    }
    

在Niecza里测试通过。（或许出于礼貌，我们应当也在Rakudo里检查一下，以保证这个不会搞砸了他们的spectest）然后记住需要修改测试文件顶头的计划
，为我们的新测试修改计数器。然后同样通过github更新。

总之，给Perl6做贡献真的很容易。每一个写Perl6代码并且向#perl6频道报告自己碰到的问题的人，都是对Perl6的真实可靠的帮助。只要你能写几行简单
的Perl6代码，你就能写spectest测试文件。这只比给Perl6配置写新方法稍微难一点点。甚至当你在折腾编译器实现过的编程语言时，你可以完全不用知道它
的编译原理而依然可能做很多有益的工作。

