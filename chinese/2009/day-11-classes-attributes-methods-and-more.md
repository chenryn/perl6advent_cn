我非常兴奋地撕下今天的礼物上闪亮的包装纸,里面是无可争议的 Perl 6 的对象模型,它内置了其类声明,角色组成,自豪的元模型(meta-model).除了有先进的功能外,让我们看看在 Perl 6 中是多么容易写一个类.

```
class Dog {
    has $.name;
    method bark($times) {
        say "w00f! " x $times;
    }
}
```

我们开始使用一个 class 的关键字.如果你有学过 Perl5 的话,你能想到的类有点像包(package)的变种,这个关键字为您提供一个优雅的语义.

接下来,我们使用 has 的关键字来声明属性访问器方法.这个"."的东西名叫 twigil. Twigil 是用来告诉你指定变量的作用域.它是"属性 + 存取方法"的组合.它的选项是：

```
has $!name;       # 私有; 只能在内部可见
has $.name is rw; # Generates an l-value accessor
```

接下来是方法的使用,并介绍使用 method 的关键字.在对象中的方法象包中的子函数,不同之处在于方法是放在类的方法列表的条目中.
它还能自动取得调用者(invocant),所以你如果没有在参数列表中加入参数.它是会给自我传递过去.在 Perl 5 中需要我们显示的写 $self = shift.

所有的类都继承一个叫 new 的默认的构造器,会自动的映射命名参数到属性,所有传进的参数会存到属性中.我们可以调用 Dog 的构造器(这个 Dog 的类的对象,并取得一个新的实例).

```
my $fido = Dog.new(name => 'Fido');
say $fido.name;  # Fido
$fido.bark(3);   # w00f! w00f! w00f!
```

请注意,Perl 6 中的方法调用操作符是"."而不是 Perl 5 中使用的"->".它缩短了 50％ 并更加合适从其他语言转过来的开发人员.

当然,很容易实现继承,下面我们建一个叫 puppy 子类 ,直接使用 is 加父类的名字就行了.

```
class Puppy is Dog {
    method bark($times) {
        say "yap! " x $times;
    }
}
```

这也支持委托,详细作用见下面的 FQA.

```
class DogWalker {
    has $.name;
    has Dog $.dog handles (dog_name => 'name');
}
my $bob = DogWalker.new(name => 'Bob', dog => $fido);
say $bob.name;      # Bob
say $bob.dog_name;  # Fido
```

在这里,我们声明指出我们想调用 DogWalker 类的名为 dog_name 的方法,并设置这个方法转到 Dog 类中包含名为 name 的方法.重命名只是其中的一个可选方式;委托常常有很多其它的实现方法.

内心深层之美比外在更加重要.所以,在整洁的语法之下是使用 meta-model(元模型)想法来实现对象.类,属性和方法都是 Perl 6 中最重要和 Meta-object 的.我们可以在运行时使用这些内省对象.

```
for Dog.^methods(:local) -> $meth {
    say "Dog has a method " ~ $meth.name;
}
```

这个 .^ 的操作是 . 操作的变种,用来替换元类(metaclass-描述类的这个对象)的调用.在这里,我们提供该类所定义的方法(Method)的列表,我们使用  :local 来排除那些从父类的继承. 这不只是给我们一个名字列表,而是方法对象的列表.其实我们直接使用这个对象来调用方法,但在这种情况下,我们只要它的名字就行.

让你了解 Meta-programming 并附送一个扩展 Perl6 的对象的功能：只要你知道声明一个方位,使用 method 的关键字让它在编译时在调用元类中的  add_method 来变成实际的方法.所以在 Perl 6 中,不仅为您提供了强大的对象模型,但也提供了机会,用来实现其它的特性,以满足未来我们还没有想到的需求.

这些都只是 Perl 6 的对象模型所提供的伟大的事情中的一些,也许我们会发现更多的东西在其他礼品中. :-)

注：
面向对象的概念

首先,我们定义几个预备性的术语.

* 构造器 (constructor):   创建一个对象的函数.
* 实例 (instance)：  一个对象的实例化实现.
* 标识 (identity)：  每个对象的实例都需要一个可以唯一标识这个实例的标记.
* 实例属性 (instance attribute)：  一个对象就是一组属性的集合.
* 实例方法 (instance method)：  所有存取或者更新对象某个实例一条或者多条属性的函数的集合.
* 类属性(class attribute)：  属于一个类中所有对象的属性,不会只在某个实例上发生变化.
* 类方法(class method)：  那些无须特定的对性实例就能够工作的从属于类的函数.
* 委托 (Delegation)： 　在对象需要执行某个工作时并不直接处理，而是要求另一个对外象代为处理(有时只处理部分工作),所以这时第二个对象代表第一个对象来执行该操作。
* 调用者(invocant):   对类来讲,调用者是包的名字,对实例方法来讲,调用者是指定对象的引用.换句话讲,调用者就是调用方法的那种东西,有的文章叫他为代理(agent)施动者(actor).
* 抽象类(abstract class):抽象类实现类的占位符，主要用来定义行为，而子类用来实现这个行为。
