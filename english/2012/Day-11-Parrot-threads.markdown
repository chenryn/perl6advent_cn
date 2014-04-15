_Editors note: I, rurban, does know almost nothing about threads. Any errors are probably mine. I just tested them, fixed some deadlocks, added the numcpu code and merged the threads branch to master._

Parrot now supports fast and lightweight OS threads, based on Nat Tucks’s initial GSoC work together with Andrew “whiteknight” Whitworth on green threads and finally Stefan Seifert’s extension to true parallel OS threads as hybrid threads. _See [http://wknight8111.blogspot.co.at/2010/08/gsoc-threads-chandons-results.html](http://wknight8111.blogspot.co.at/2010/08/gsoc-threads-chandons-results.html) and [http://niner.name/Hybrid_Threads_for_the_Parrot_VM.pdf](http://niner.name/Hybrid_Threads_for_the_Parrot_VM.pdf)_

Parrot always supported _“threads”_, i.e. concurrency models over the last years, but we identified various problems with the particular designs and were continuously improving them. In our case without changing the API too much, as the pdd25 concurrency spec is pretty high level, describing the various models parrot should support, and also pretty low-level in describing the two PMC’s which export the threads API, the **Task** and the **Scheduler** classes.

Being born at a time when Perl 6 still looked much more similar to Perl 5 than it does nowadays, Parrot’s threading support initially was very close to Perl’s ithreads model. Previous attempts to change this into the more conventional model of data shared by default or implementing new technologies like STM “Software Transactional Memory” failed. For example Parrot has never supported running multiple threads and having garbage collection at the same time.

In the year 2005 development of faster Central Processing Units (CPUs) shifted from increased speed of a single core to adding more cores. Modern processors contain up to 12 cores with even mobile phones having up to four. To utilize a modern CPU’s power, code needs to be run in parallel. In UNIX (and thus Perl) tradition, this is accomplished using multiple processes being a good solution for many use cases. For many others like auto threading of hyper operators in Perl 6, the cost of process setup and communication would be prohibitively high except for very large data sets.

During the years of back and forth and failed attempts of adding threading support to Parrot, the Perl 6 specification evolved to a point where the largest parts of the language were covered and its features were implemented in the compilers. The lack of concurrency primitives in Parrot however prevents any progress in the area of concurrency support.

Green threads were used to simplify the implementation of a nearly lock free multithreading implementation. [http://niner.name/Hybrid_Threads_for_the_Parrot_VM.pdf](http://niner.name/Hybrid_Threads_for_the_Parrot_VM.pdf)

Parrot supports now native Win32 threads and POSIX threads. Win32 alarm, sleep and premption is unified with POSIX, it is handled on a common timer thread.

Parrot creates at startup a thread pool of `--numthreads` threads, which defaults to the number of available CPU cores. Activating a new thread at runtime causes no run-time penalties, until the number of cores is utilized. When a user starts a new task, the scheduler first looks for an idle thread. If one can be found, the task is scheduled on the thread’s interpreter. If more tasks are started than the maximum number of threads, the tasks are distributed evenly among the running interpreters. This is effectively an implementation of the N:M threading model.

## Green threads

Our GSOC student Nan “Chandor” Tuck worked in summer 2010 on green threads.

_What I have working now is a pre-emptively scheduled green threads system for Parrot that allows programs to be written in a concurrent style. Individual green threads can do basic blocking file input without stopping other threads from running. These logical threads are accessed using the Task API that I described a couple weeks ago._ _This functionality makes Parrot similarly powerful at threading as the standard version of Ruby or Python: Threads can do pretty much everything except run at the same time._[http://parrot.org/content/hybrid-threads-gsoc-project-results](http://parrot.org/content/hybrid-threads-gsoc-project-results)

What was missing from this green threads branch was true parallel execution in OS threads, one global_interpreter structure that is shared and protected by locks or other concurrent access rules and many local_interpreters that run simultaneously in separate OS threads.

## + OS threads

From Fall 2011 to Summer 2012 Stefan “nine” Seifert implemented true OS threads on top of green threads to finally allow true parallel execution of Tasks, to implement blocking IO, and to give perl6 some more advantages over perl5.

The lightweight “green” threads are used as messages in a system where reading shared variables is allowed but only the one owner thread may write to it. That’s why we call it hybrid threads.

## Why is multithreading support so difficult to implement?

Low level programming languages like C provide only the bare necessities, leaving the responsibility for preventing data corruption and synchronization entirely to the user. A high-level language like Perl 6 on the other hand provides complex and compound data types, handles garbage collection and a very dynamic object system. Even seemingly simple things like a method call can become very complex. In a statically typed programming language the definition of a class is immutable. Thus, calling a method on an object contains just the steps of determining the object’s class, fetching the required method from this class and calling it. Calling the same method again can then even omit the first two steps since their results cannot change.

In a dynamic language, the object may change its class at runtime. The inheritance hierarchy of the class may be changed by adding or removing parent classes. Methods may be added to or removed from classes (or objects) at runtime and even the way how to find a method of a class may change. So a simple method call results in the following steps:

    
        ·  determining the class of the object,
        ·  determining the method resolution method of the class,
        ·  finding the actual method to call,
        ·  calling the method.

These steps have to be repeated for every method call, because the results may change any time. In a threaded environment, a thread running in parallel may change the underlying data and meta data in between those sequences and even between those steps. As a consequence, this meta data has to be protected from corruption introducing the need for locks in a performance critical area.

Many interpreters for dynamic languages like Python or Ruby handle this problem by using a global interpreter lock (GIL) to effectively serialize all operations. This is a proven and reliable way but leaves much of the hardware’s potential unused.

## Java

In Java, the user is responsible for preventing concurrency issues. The language provides synchronization primitives like mutexes, but the interpreter (the Java Virtual Machine, JVM) does not protect the consistency of the provided data structures. The class library provides the user with high-level data structures explicitly designed for multithreaded scenarios.

Java version 1.1 used green threads to support multithreaded execution of Java programs. Green threads are threads simulated by the virtual machine (VM) but unable to use more than one CPU core for processing. Version 1.2 introduced native Operating System (OS) threading support which since has become the standard way to do multithreading in Java.

## Python

The CPython implementation of the Python runtime uses a Global Inter- preter Lock (GIL) to protect its internal consistency. This is a single lock taken whenever the interpreter executes Python bytecode. Because of this lock, only one thread can execute bytecode at any time so all built-in types and the object model are implicitly type safe. The drawback is that Python code cannot benefit from having multiple CPU cores available. However I/O operations and calls to external libraries are executed without holding the GIL, so in applications with multiple I/O bounded threads, there may still be a performance benefit from using multithreading.

To run Python code in parallel, multiple processes have to be used. The multiprocessing module provides support for spawning processes exposed through an API similar to the threading module. Since processes may not directly access other processes’ memory, the multiprocessing module pro- vides several means of communication between processes: Queues, Pipes and shared memory support.

## Parrot

Much of Parrot’s previous threading related code has been removed to clean up the code and improve performance. Since the existing threading support was known to be unreliable and seriously flawed, this was no trade off. The final parts were removed by the merging of the `kill_threads` branch on September, 21st 2011.

In 2010, Nat Tuck began working on a `green_threads` branch during his Google Summer of Code internship. The feature got prototyped using pure PIR and then implemented in Parrot’s core. He got it to work in simple cases and started to work on OS thread support but the internship ended before the code was ready to be merged into the master branch. The code lay dormant until the work on hybrid threads in the `threads` branch started in 2011.

In Parrot, green threads are called Tasks. Each task is assigned a fixed amount of execution time. After this time is up a timer callback sets a flag which is checked at execution of every branch operation. Since the interpreter’s state is well defined at this point, its internal consistency is guaran- teed. The same holds for the GC. Since task preemption is only done while executing user-level code, the GC can do its work undisturbed and without the need for measures like locking. Since user-level code is allowed to dis- able the scheduler, it can be guaranteed to run undisturbed through critical sections.

The scheduler is implemented as a PMC type. This allows the user to subclass this PMC thus allowing fine-grained control over the scheduling policy. Features, a user could add this way would be for example giving different priorities to tasks or implementing the possibility to suspend and resume a task.

## Shared data

Cross-thread writes to shared variables may endanger the internal consistency of the interpreter. Traditionally, the solution to this problem is the use of locks of varying granularity. Fine-grained locking allows code to run in parallel but taking and releasing locks costs per- formance. It not only increases the instruction count and memory accesses but it also forces the CPU cores to coordinate and thus communicate. Even a seemingly simple operation like an atomic increment can take two orders of magnitude longer than a normal increment. While the gain through being able to utilize multiple CPU cores may offset this cost, it is still impacting the common case of having only a single thread running.

Too coarse locking on the other hand would reduce scalability and the performance gains through parallel execution by having threads wait for extended periods for locks to become available. In the extreme case of having a global interpreter lock it would effectively serialize all computations costing much of the benefits of using threads in the first place.

The other problem with locking is the possibility of introducing deadlocks. For example, two functions F1 and F2 both use two resources A and B protected by locks. If F1 first locks A and then tries to lock B while F2 has already locked B and is now trying to lock A, the program would come to a halt. Both functions would be left waiting for the other to unlock the resource which will never happen. With fine-grained locking, the possibilities for such bugs grow quickly. At the same time, it is easy to miss a case where a lock would be appropriate leading to difficult to diagnose corruption bugs.

The solution for these problems implemented in this thesis is to sidestep them altogether by disallowing write access to shared variables. The programmer (or in most cases the compiler) is obliged to declare a list of all shared variables before a newly created task is started. The interpreter would then create proxy objects for these variables which the task can use to access the data. These proxies contain references to the original objects. They use these references to forward all reading vtable functions to the originals. Write access on the other hand would lead to a runtime error.

In other words, all data is owned by the thread creating it and only the owner may write to it. Other threads have only read access.

For threads to be able to communicate with their creators and other threads, they still need to write to shared variables. This is where green threads come into play. Since green threads are light weight, it is feasible for a thread to create a task just for updating a variable. This task is scheduled on the interpreter owning this variable. To reduce latency, the task is flagged to run immediately. The data-owning interpreter will preempt the currently running task and process the new write task. Put another way, the data-owning interpreter is told what to write to its variables, so other threads don’t have to.

## Proxies

Proxies are the arbiters between threads. They are the only means for a thread to access another thread’s data and are implemented by the Proxy PMC type.

Proxy has default implementations for all functions, writing functions raise a cant_do_write_method runtime exception. If a method returns a PMC from the target’s interp, another proxy object has to be created and wrapped around it so it can be safely returned to the caller.

## Sub

The Sub PMC represents executable subroutines. A Sub does not only contain the code to execute but also the context in which to execute the code such as visible globals and namespaces. If a proxy to such a Sub were created and invoke called on it, the code would access this context directly since it belongs to the same interp as the proxied Sub itself. Thus, an operation like `get_global` fetches a global from an unproxied namespace and an unproxied global is be put into the target register. Since this is happening while running invoke on the original Sub, Proxy cannot intercept the call and create a Proxy for the result.

This is the reason why `Parrot_thread_create_proxy` does not create a Proxy for a Sub but uses `Parrot_thread_create_local_sub` to create a copy on the thread’s interp with proxies for all PMC attributes.

## Writing to shared variables

As described in chapter 5, to write to shared variables, a thread creates a task and schedules it on the data owning interpreter. An example task looks like this:

    
        .sub write_to_variable
             .param pmc variable
             variable = 1
        .end

This is a subroutine with just one parameter. The variable passed as this parameter is the one the task should write to. In this case the constant value 1 would be written to the variable. In PIR, an assignment to a PMC gets translated to a method call. In this case, the set_integer_native is called changing the variable’s value. Since PMCs are passed by reference, it is the original variable which gets written to.

Code to create the task looks like:

    
        1    write_task = new ['Task']
        2    setattribute write_task, 'code', write_to_variable
        3    setattribute write_task, 'data', shared_variable
        4    interp.'schedule_proxied'(write_task, shared_variable)

Line 1 creates a new task object. The example subroutine is used for the task’s code attribute. `shared_variable` is used for data. At this point, `shared_variable` is actually the proxy object created for the shared integer PMC. The interpreter object contains a `schedule_proxied` method which is used to schedule the `write_task` on the thread owning the original variable.

`schedule_proxied` uses `Parrot_thread_create_local_task` which in this case detects that the data given as parameter for the task’s code is actu- ally a proxy already and unwraps the proxied object. `Parrot_cx_schedule_immediate` is then used to make the data owning interpreter execute the task as soon as possible.

To protect a critical section, preemption can be disabled so the critical section runs uninterrupted:

    
        1 .sub swap_variables
        2     .param pmc a, b
        3     .local temp
        4     disable_preemption
        5     temp = a
        6     a = b
        7     b = temp
        8     enable_preemption
        9 .end

### wait

Using tasks to write to shared variables makes such actions inherently asynchronous. This is not always what is needed by the implemented algorithm. For example, when the shared variable is a lock, processing should continue as soon as it’s acquired. The wait operation is used to wait for a task’s completion. The waiting task is added to the waited for task’s waiters list and preempted immediately. When a task finishes, all the tasks in the waiters list are scheduled again for execution. Since for each task a local copy is created on the target thread, the running task not only checks its own waiters list but also its partner’s.

If a task on the main thread was waiting for a task on another thread to finish and no other tasks are in the scheduler’s queue on the main thread, the main thread exits if no alarms are pending. To prevent this unintended exit, all tasks are added to the scheduler’s foreign_tasks list when they are scheduled on other threads. To end the program with other threads still running, an explicit exit operation has to be used.

## Benchmarks

Preliminary benchmarks have shown Parrot’s performance to be within an order of magnitude of that of an optimized implementation in Perl 5.

Since Parrot does not yet offer the user any synchronization primitives, locks had to be implemented using a shared variable which is written to only by the main thread. Replacing this primitive method with a native semaphore implementation would probably reduce runtime to a small fraction.

### Runtime comparison for matrix multiplication

    
                    singlethreaded  computation      multithreaded   computation
        1. run          28.522 s       19.530 s        17.543 s          8.478 s
        2. run          28.427 s       19.463 s        17.320 s          8.283 s
        3. run          28.200 s       19.235 s        17.489 s          8.473 s
        average         28.383 s       19.409 s        17.451 s          8.411 s

This test implements matrix multiplication using four threads. For simplicity the second matrix only has one column. The program is written in the Winxed programming language. Winxed is a low-level language with Javascript like syntax and the possibility to include sections of PIR code verbatim making it possible to try experimental opcodes while writing more readable and concise code than with PIR alone. The complete source code is available in [examples/threads/matrix_part.winxed](https://github.com/parrot/parrot/blob/master/examples/threads/matrix_part.winxed)

The program consists of the parts initialization, computation and verification. Computation is parallelized using four tasks each calculating one fourth of the result vector. Runtime is compared to a simple singlethreaded implementation. Run times were measured using the time command and are recorded in the above table.

As can be seen, the multithreaded implementation gives an average speedup of 2.31 for the computation and 1.61 in total.

### Runtime comparison for Mandelbrot set calculation

    
                     singlethreaded  1 thread    2 threads   4 threads    8 threads
        1. run           89.931 s    89.978 s    45.813 s     24.028 s     17.445 s
        2. run           89.707 s    89.871 s    45.906 s     24.048 s     17.695 s
        3. run           90.318 s    89.839 s    45.951 s     24.049 s     17.573 s
        average          89.985 s    89.896 s    45.890 s     24.042 s     17.571 s
        speedup           1.000        1.001       1.959       3.739        5.116

The complete source code is available in [examples/pir/mandel.pir](https://github.com/parrot/parrot/blob/master/examples/pir/mandel.pir)

Calculating an image of the Mandelbrot set is a common benchmark for multithreading implementations since calculations of points are independent of each other and are thus easily parallelizable. A simple implementation of the escape time algorithm written in Winxed has been used to determine scalability properties of the threading implementation. The image is split into lines which are calculated alternatedly by a configured number of tasks. Run times were measured using the time command on an Intel Core i7 3770K processor with 16 GiB RAM running openSUSE 12.1 and are recorded in the Mandelbrot table. As can be seen, the implementation scales nearly linearly up to four threads reflecting the CPUs four physical cores. Using eight threads, the speedup is only 1.368 compared to four threads but this seems to be more a limitation of the hardware than the implementation.

## Questions

On IRC and ob the mailing list some detailed questions have been asked.

See here: [http://lists.parrot.org/pipermail/parrot-dev/2012-December/007295.html](http://lists.parrot.org/pipermail/parrot-dev/2012-December/007295.html)

