对于很多人来说，文法(Grammar)是Perl6最令人兴奋的特性之一了。他们面向对象的统一解析文法(grammar)里的每一个生产规则(productio
n rule)，仅仅通过一个稍微特殊些些的方法(method)，这种方法就是用关键字"regex"/"rule"/"token"声明。在回溯和空白处理的时候
，这几个关键字会给你分别提供不同的默认行为。一般地说，就是他们会用Perl6的规则句法(syntax)来解析方法的内容。而在引擎里，他们其实也就是方法。包括
相互关联的生产规则，其实也是方法调用。(译者注：这段翻译别扭无比......)

