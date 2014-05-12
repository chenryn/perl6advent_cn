<>
* [名称][1]
* [描述][2]
* [小细节][3]
  * [Sigils][4]
  * [哈希项不再自动加引号][5]
  * [全局变量有副缀符][6]
  * [命令行参数][7]
  * [引用数组和哈希元素的新方法][8]
  * [双下划线关键词被取消了][9]
  * [上下文][10]
* [Operators][11]
  * [qw() changes; new interpolating form][12]
  * [其他重要的操作符变动][13]
* [代码块和语句][14]
  * [控制结构条件不再用括号][15]
  * [eval \{\} is now try \{\}][16]
  * [foreach becomes for][17]
  * [for becomes loop][18]
* [正则和规则][19]
  * [新的正则语法][20]
  * [现在默认即匿名正则][21]
* [Subroutines][22]
* [Formats][23]
* [Packages][24]
* [Modules][25]
* [Objects][26]
  * [Method invocation changes from -&gt; to .][27]
  * [Dynamic method calls distinguish symbolic refs from hard refs][28]
  * [Built-in functions are now methods][29]
* [Overloading][30]
  * [提供哈希和列表语义][31]
  * [Chaining file test operators has changed][32]
* [内置函数][33]
  * [References are gone (or: everything is a reference)][34]
  * [say()][35]
  * [wantarray() is gone][36]
* [作者][37]

# [名称][38]

Perl6::Perl5::Differences -- Perl 5 和 Perl 6 的差别

# [描述][39]

该文档是为刚接触 Perl 6、打算快速了解两者差异的 Perl 5 工程师所准备。一切细节都可以在链接的语言设计文档中找到。很多时候，你可以直接在 Perl 6 里写 Perl 5 代码，编译器会告诉你哪里有问题。注意这里不可能覆盖全部差异，比如有时候旧语法在 Perl 6 中有了新含义。

下面的列表目前还处于未完成状态。

# [小细节][40]

## [前缀符号][41]

过去你写的是：

    my @fruits = ("apple", "pear", "banana");
    print $fruit[0], "\\n";

现在你要写成：

    my @fruits = "apple", "pear", "banana";
    say @fruit[0];

还有，用 `<>` 操作符，代替 `qw()`:

    my @fruits = &lt;apple pear banana&gt;;

注意在获取单个元素的时候，前缀符从 `$` 变成了 `@`；或许你可以理解成变量的前缀符现在是变量名的一部分，所以不再会变化了。对于哈希，这个改动也是同样的。

更多细节阅读 ["Names and Variables" in S02][42].

## [哈希项不再自动加引号][43]

哈希项不再自动加引号:

    曾经:    $days\{February\}
    现在:    %days\{'February'\}
    或者:     %days&lt;February&gt;
    或者:     %days&lt;&lt;February&gt;&gt;

花括号依然可以用，不过花括号目前主要用于代码块相关，所以这里其实你得到的是一个返回值为"February"的代码块。而 `<>` 和 `<<>>` 事实上才是加引号标注的语法（见下）。

## [全局变量有副缀符][44]

是的，副缀符。即变量名的第二个字符。对于全局变量，就是一个 `*`。

    曾经:    $ENV\{FOO\}
    现在:    %\*ENV&lt;FOO&gt;

更多细节阅读 ["Names and Variables" in S02][45].

## [命令行参数][46]

命令行参数现在存在 `@*ARGS` 里，而不是 `@ARGV`。同样要注意到这个 `*` 副缀符，因为 `@*ARGS` 是一个全局变量。

## [引用数组和哈希元素的新方法][47]

数组元素个数：

    曾经:    $#array+1 或者 scalar(@array)
    现在:    @array.elems

数组最后一个元素的索引值：

    曾经:    $#array
    现在:    @array.end

然后，数组的最后一个元素：

    曾经:    $array[$#array]
    现在:    @array[@array.end]
            @array[\*-1]              # 注意这个星号

更多细节阅读 ["Built-In Data Types" in S02][48]

## [双下划线关键词被取消了][49]

    过去                 现在
    ---                 ---
    \_\_LINE\_\_            $?LINE
    \_\_FILE\_\_            $?FILE
    \_\_PACKAGE\_\_         $?PACKAGE
    \_\_END\_\_             =begin END
    \_\_DATA\_\_            =begin DATA

阅读 ["double-underscore forms are going away" in S02][50] 查看更多细节。副缀符 `?` 表示数据是在编译期就可知的。

## [上下文][51]

依然有三种主要的上下文，void, item (也就是以前的 scalar) 和 list。还增加了很多特定上下文，以及强制这些上下文的操作符。

    my @array = 1, 2, 3;

    # 生成 item 上下文
    my $a = @array; say $a.WHAT;    # prints Array

    # string 上下文
    say ~@array;                    # "1 2 3"

    # numeric 上下文
    say +@array;                    # 3

    # boolean 上下文
    my $is-nonempty = ?@array;

单引号 `'` 和短横杠 `-` 也可以作为变量名的一部分，只要处于两个字母之间即可。

# [操作符][52]

完整的操作符变更清单写在了 ["Changes to Perl 5 operators" in S03][53] 和 ["New operators" in S03][54] 里。

一些高亮示例：

## [`qw()` 改了；现在有新的内插格式][55]

    曾经:    qw(foo)
    现在:    &lt;foo&gt;

    曾经:    split ' ', "foo $bar bat"
    现在:    &lt;&lt;foo $bar bat&gt;&gt;

引号操作符现在也可以被修改(很像 Perl 5 里的正则和替换)，你甚至可以定义自己专有的引号操作符。更多细节见 [S03][56]。

注意 `()` 现在是函数调用，所以 `qw(a b)` 你应该写成 `qw<a b>` 或 `qw[a b]` (如果你真的不喜欢写 `<a b>` 的话，那么这样也行)。

## [其他重要的操作符变动][57]

字符串连接现在用 `~`。

正则匹配现在用 `~~`，Perl 5 的 `=~` 取消了。

    if "abc" ~~ m/a/ \{ ... \}

`|` 和 `&` 作为中缀操作符目前用来构建 Junction。而  AND 和 OR 操作符分成了不同的字符串和数值操作符。字符串的 AND 写作 `~&` ，数值的 AND 写作 `+&` 。`~|` 是字符串的 OR 等等。

    曾经: $foo &amp; 1;
    现在: $foo +&amp; 1;

位操作符现在在前面加上了 +， ~ 或者 ? ，这取决与数据类型是数值、字符串还是真假。

    曾经: $foo &lt;&lt; 42;
    现在: $foo +&lt; 42;

赋值操作符也以类似的方式做了改动：

    曾经: $foo &lt;&lt;= 42;
    现在: $foo +&lt;= 42;

圆括号不再构建列表，而仅仅是组。列表通过逗号操作符构建。这样就收紧了列表赋值操作符的优先级，所以你可以不用括号直接书写列表赋值：

    my @list = 1, 2, 3;     # @list 就有三个元素了

箭头操作符 `->` 不再用于解引用。因为所有东西都是对象，解引用的圆括号直接就是方法调用，所以你可以在索引或者方法调用的时候使用括号：

    my $aoa = [[1, 2, 3], [4, 5, 6], [7, 8, 9]];
    say $aoa[1]\[0];         # 4

    my $s = sub \{ say "hi" \};
    $s();
    # or
    $s.();
    $lol.[1]\[0]

# [代码块和语句][58]

Perl6 中代码块和语句的完整规范阅读 [S04][59]。

## [控制结构条件不再用括号][60]

    曾经:    if ($a &lt; $b) \{ ... \}
    现在:    if  $a &lt; $b  \{ ... \}

同样的还有 `while`， `for` 等等。如果你一定想要用括号，记住在 `if` 后面一定要有个空格，不然就编程函数调用了。

## [eval \{\} 现在叫 try \{\}][61]

用 `eval` 执行代码块现在改成了 `try`。

    曾经:  eval \{
            # ...
          \};
          if ($@) \{
            warn "oops: $@";
          \}
    现在:  try  \{
             # ...
             CATCH \{ warn "oops: $!" \}
          \}

CATCH 提供了更灵活的错误处理。细节请阅读 ["Exception\_handlers" in S04][62] 。

## [foreach 变成 for][63]

    曾经:    foreach (@whatever) \{ ... \}
    现在:    for @whatever       \{ ... \}

同样，不用 `$_` 而赋值给本地变量的方式也变了：

    曾经:    foreach my $x (@whatever) \{ ... \}
    现在:    for @whatever -&gt; $x       \{ ... \}

还可以增强成每次获取多个元素：

    曾经:    while (my($age, $sex, $location) = splice @whatever, 0, 3) \{ ... \}
    现在:    for @whatever -&gt; $age, $sex, $location \{ ... \}

(不过 `for` 的版本不会销毁数组)

细节请阅读 ["The for statement" in S04][64] 和 ["each" in S29][65]。

## [for 变成 loop][66]

    曾经:    for  ($i=0; $i&lt;10; $i++) \{ ... \}
    现在:    loop ($i=0; $i&lt;10; $i++) \{ ... \}

`loop` 也可以用作死循环：

    曾经:    while (1) \{ ... \}
    现在:    loop \{ ... \}

# [正则和规则][67]

## [新的正则语法][68]

下面是一个 Perl5 正则表达式转换成 Perl6 的简单示例：

    曾经:    $str =~ m/^\\d\{2,5\}\\s/i
    现在:    $str ~~ m:P5:i/^\\d\{2,5\}\\s/

这里使用 `:P5` 是因为标准的 Perl6 语法完全不一样。'P5' 表示这是一个 Perl5 兼容的语法。要做替换的话：

    曾经:    $str =~ s/(a)/$1/e;
    现在:    $str ~~ s:P5/(a)/\{$0\}/;

注意过去的 `$1` 现在从 `$0` 开始了。而且 `/e` 也被取消了，采用内嵌的闭合符号。

## [现在默认即匿名正则][69]

现在默认即匿名正则，除非是在布尔上下文里。

    曾经:    my @regexpes = (
                qr/abc/,
                qr/def/,
            );
    现在:    my @regexpes = (
                /abc/,
                /def/,
            );

当然，你还是可以显式标记正则为匿名，`qr//` 操作符现在写作 `rx//` (注: **r**ege**x**) 或者 `regex { }`。

完整规范阅读 [S05][70]。还可以参考：

相关的启示录，说明了这些变化：

  http://dev.perl.org/perl6/doc/design/apo/A05.html

以及相关的解释，解释了更多细节：

  http://dev.perl.org/perl6/doc/design/exe/E05.html

# [Subroutines][71]

# [Formats][72]

Formats will be handled by external libraries.

# [Packages][73]

# [Modules][74]

# [Objects][75]

Perl 6 有了"真正"的对象系统，有了类、方法、属性等等对应的关键词。公有属性用 `.` 副缀符，私有属性用 `!` 副缀符。

    class YourClass \{
        has $!private;
        has @.public;

        # 带有写访问器
        has $.stuff is rw;

        method do\_something \{
            if self.can('bark') \{
                say "Something doggy";
            \}
        \}
    \}

## [方法调用从 -&gt; 变成 .][76]

    曾经:    $object-&gt;method
    现在:    $object.method

## [动态方法调用区分软引用还是硬引用][77]

    曾经: $self-&gt;$method()
    现在: $self.$method()      # hard ref
    现在: $self."$method"()    # symbolic ref

## [内建函数现在都是方法][78]

绝大多数内建函数现在都是一些内建类比如 `String`, `Array` 等的方法。

    曾经:    my $len = length($string);
    现在:    my $len = $string.chars;

    曾经:    print sort(@array);
    现在:    print @array.sort;
            @array.sort.print;

如果你喜欢非 OO 的风格，你依然可以写 `sort(@array)` 。

# [重载][79]

因为内建函数和操作符都已经是 multi 类型的函数或者方法了，为不同类型改变他们的行为异常简单，继续定义 multi 函数或者方法就好了。如果你想要全局生效，再放进 `GLOBAL` 名字空间就好：

    multi sub GLOBAL::uc(TurkishStr $str) \{ ... \}

    # 重载字符串连接
    multi sub infix:&lt;~&gt;(TurkishStr $us, TurkishStr $them) \{ ... \}

如果你想转换一个类型成另一个类型，只需要在该类型下提供一个跟目的类型同名的方法即可。

    sub needs\_bar(Bar $x) \{ ... \}
    class Foo \{
        ...
        # coercion to type Bar:
        method Bar \{ ... \}
    \}

    needs\_bar(Foo.new);         # coerces to Bar

## [提供哈希和列表语义][80]

如果你想写一个类，它的对象可以被赋值给一个有 `@` 前缀符的变量，你需要实现 `Positional` 角色。同理，`%` 前缀符变量需要实现 `Associative` 角色，`&` 前缀符需要实现 `Callable`。

这些角色提供下列操作符： `postcircumfix:<[ ]>` (Positional，用于数组索引), `postcircumfix:<{ }>` (Associative) 和 `postcircumfix:<()>` (Callable)。他们从技术上说都只是方法而已。你可以重写他们以提供其他语义。

    class OrderedHash does Associative \{
        multi method postcircumfix:&lt;\{ \}&gt;(Int $index) \{
            # code for accessing single hash elements here
        \}
        multi method postcircumfix:&lt;\{ \}&gt;(\*\*@slice) \{
            # code for accessing hash slices here
        \}
        ...
    \}

    my %orderedHash = OrderedHash.new();
    say %orderedHash\{'a'\};

更多细节阅读 [S13][81]。

## [链式文件测试操作符被改变了][82]

    曾经: if (-r $file &amp;&amp; -x \_) \{...\}
    现在: if $file ~~ :r &amp; :x  \{...\}

更多细节阅读 ["Changes to Perl 5 operators"/"The filetest operators now return a result that is both a boolean" in S03][83]

# [内置函数][84]

不少内置函数被移除了，细节请见：

["Obsolete Functions" in S29][85]

## [引用被取消了(或者说：万物皆引用了)][86]

`Capture` 对象填补了 Perl 6 中引用的位置。你可以想象它是"胖"引用，不单可以获取单个对象的身份，还可以获取多个相关对象的关联身份。反过来说，你可以想象 Perl 5 的引用是一个缩水版的 `Capture`，只能用于你只想获取单个元素身份的时候。

    曾经: ref $foo eq 'HASH'
    现在: $foo ~~ Hash

    曾经: @new = (ref $old eq 'ARRAY' ) ? @$old : ($old);
    现在: @new = @$old;

    曾经: %h = ( k =&gt; \\@a );
    现在: %h = ( k =&gt; @a );

要传递一个引用：

    曾经: sub foo \{...\};        foo(\\$bar)
    现在: sub foo ($bar is rw); foo($bar)

上面提到的"废弃"都有细节描述。你也可以阅读 ["Names\_and\_Variables" in S02][87] 下的 _Capture_ 或者 [Perl6::FAQ::Capture][88]。

## [say()][89]

这是 `print` 自动补回车的版本：

    曾经:    print "Hello, world!\\n";
    现在:    say   "Hello, world!";

太经常用的东西就应该成为语言的一部分。这个变动也引回了 Perl 5，在 `use v5.10` 之后，你也可以用 `say` 了。

## [wantarray() 取消][90]

`wantarray` 取消了，在 Perl 6 里上下文是流动的，也就是说函数不会知道自己存在于什么上下文里。

所以你需要返回一个在任意上下文中都可以正确处理的对象。

# [作者][91]

Kirrily "Skud" Robert, `<skud@cpan.org>`, Mark Stosberg, Moritz Lenz, Trey Harris, Andy Lester

  [1]: #名称
  [2]: #描述
  [3]: #Bits_and_Pieces
  [4]: #Sigils
  [5]: #Hash_elements_no_longer_auto-quote
  [6]: #Global_variables_have_a_twigil
  [7]: #Command-line_arguments
  [8]: #New_ways_of_referring_to_array_and_hash_elements
  [9]: #The_double-underscore_keywords_are_gone
  [10]: #上下文
  [11]: #Operators
  [12]: #qw()_changes%3B_new_interpolating_form
  [13]: #Other_important_operator_changes
  [14]: #Blocks_and_Statements
  [15]: #You_don%27t_need_parens_on_control_structure_conditions
  [16]: #eval_%7B%7D_is_now_try_%7B%7D
  [17]: #foreach_becomes_for
  [18]: #for_becomes_loop
  [19]: #Regexes_and_Rules
  [20]: #New_regex_syntax
  [21]: #Anonymous_regexpes_are_now_default
  [22]: #Subroutines
  [23]: #Formats
  [24]: #Packages
  [25]: #Modules
  [26]: #Objects
  [27]: #Method_invocation_changes_from_-%3E_to_.
  [28]: #Dynamic_method_calls_distinguish_symbolic_refs_from_hard_refs
  [29]: #Built-in_functions_are_now_methods
  [30]: #Overloading
  [31]: #Offering_Hash_and_List_semantics
  [32]: #Chaining_file_test_operators_has_changed
  [33]: #Builtin_Functions
  [34]: #References_are_gone_(or%3A_everything_is_a_reference)
  [35]: #say()
  [36]: #wantarray()_is_gone
  [37]: #作者
  [38]: #___top "click to go to top of document"
  [39]: #___top "click to go to top of document"
  [40]: #___top "click to go to top of document"
  [41]: #___top "click to go to top of document"
  [42]: http://feather.perl6.nl/syn/S02.html#Names_and_Variables
  [43]: #___top "click to go to top of document"
  [44]: #___top "click to go to top of document"
  [45]: http://feather.perl6.nl/syn/S02.html#Names_and_Variables
  [46]: #___top "click to go to top of document"
  [47]: #___top "click to go to top of document"
  [48]: http://feather.perl6.nl/syn/S02.html#Built-In_Data_Types
  [49]: #___top "click to go to top of document"
  [50]: http://feather.perl6.nl/syn/S02.html#double-underscore_forms_are_going_away
  [51]: #___top "click to go to top of document"
  [52]: #___top "click to go to top of document"
  [53]: http://feather.perl6.nl/syn/S03.html#Changes_to_Perl_5_operators
  [54]: http://feather.perl6.nl/syn/S03.html#New_operators
  [55]: #___top "click to go to top of document"
  [56]: http://feather.perl6.nl/syn/S03.html
  [57]: #___top "click to go to top of document"
  [58]: #___top "click to go to top of document"
  [59]: http://feather.perl6.nl/syn/S04.html
  [60]: #___top "click to go to top of document"
  [61]: #___top "click to go to top of document"
  [62]: http://feather.perl6.nl/syn/S04.html#Exception_handlers
  [63]: #___top "click to go to top of document"
  [64]: http://feather.perl6.nl/syn/S04.html#The_for_statement
  [65]: http://feather.perl6.nl/syn/S29.html#each
  [66]: #___top "click to go to top of document"
  [67]: #___top "click to go to top of document"
  [68]: #___top "click to go to top of document"
  [69]: #___top "click to go to top of document"
  [70]: http://feather.perl6.nl/syn/S05.html
  [71]: #___top "click to go to top of document"
  [72]: #___top "click to go to top of document"
  [73]: #___top "click to go to top of document"
  [74]: #___top "click to go to top of document"
  [75]: #___top "click to go to top of document"
  [76]: #___top "click to go to top of document"
  [77]: #___top "click to go to top of document"
  [78]: #___top "click to go to top of document"
  [79]: #___top "click to go to top of document"
  [80]: #___top "click to go to top of document"
  [81]: http://feather.perl6.nl/syn/S13.html
  [82]: #___top "click to go to top of document"
  [83]: http://feather.perl6.nl/syn/S03.html#Changes_to_Perl_5_operators%22%2F%22The_filetest_operators_now_return_a_result_that_is_both_a_boolean
  [84]: #___top "click to go to top of document"
  [85]: http://feather.perl6.nl/syn/S29.html#Obsolete_Functions
  [86]: #___top "click to go to top of document"
  [87]: http://feather.perl6.nl/syn/S02.html#Names_and_Variables
  [88]: http://feather.perl6.nl/syn/Perl6%3A%3AFAQ%3A%3ACapture.html
  [89]: #___top "click to go to top of document"
  [90]: #___top "click to go to top of document"
  [91]: #___top "click to go to top of document"
