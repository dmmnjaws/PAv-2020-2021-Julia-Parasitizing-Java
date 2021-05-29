# PAv-2020-2021-Julia-Parasitizing-Java

## NOTES

- One of our main focuses is to not compromise any of Julia's semantics in order to allow invocations to the JVM from Julia.

- Since for each new method, we generate all generic functions for that receiver when we call ir the first time, our Java-Parazite-Julia has a bigger start up time.

- With time we realized it would be interesting to explore two alternatives to the generic-function generation of Java-Parazite Julia: One that generates the methods on-demand (when a method is called for the first time), and another that generates the methods upon startup (similarly to Java, imports (jimport) should be done in the beginning).

- All development, testing and benchmarking were conducted in Julia 1.5.3 and Java 1.8.0

## LIMITATIONS

- Java supports invocation of static methods in null objects, because these still have a defined type. (ex: Math math = null is of type Math). However we don't support this in our implementation of Java-Parazite-Julia, because we can't (found no way to...), assign a DataType to a nothing in Julia, like we can assign a Class to a null in Java. (*Both LoadOnDemand and LoadOnStartup feature this limitation.*)

- Using a @jcall call nested in a Julia method unfortunately isn't possible. Since we don't generate all generic functions upon import of a class, but only upon calling, on demand, Julia will not be able to evaluate a @jcall call, and will warn the user that it's trying to call a method not yet defined. This is something we unfortunately didn't predict early on, and fixing it requires a remodeling of our entire code. A possible approach would be for the generic functions to be pre-loaded, via a mechanim involving static import as the first lines of a Java-Parazite Julia program, just like it's done in Java, substituting the current loaded-on-demand approach. - This renders Java-Parazite Julia only useful for simple realtime calls to Java, for now... (*This limitation was solved by the LoadOnStartup approach, therefore it's exclusive to the LoadOnDemand approach.*)

- Class hierarchies are not recognized, for instance: A method that takes an Object, isn't able to be called with a String. (But it should.) Even though an extention to support this wasn't implemented yet, our approach to generic functions had the accomodation of this feature in mind, requiring the aditional reification of the Java class hierarchies, in Julia. If such reification exists, Julia should be able to select a method from a given generic function accordingly (and even making use of Mulitple Dispatch) (*Both LoadOnDemand and LoadOnStartup feature this limitation.*)

## COMPARING LoadOnDemand and LoadOnStartup

**Brief summary of the two approaches:**

- LoadOnDemand: This was the first approach we implemented. In this approach, the generic function that reifies a Java Class' methods with a given name is generated whenever a method with said name and said class as receiver is invoked using Java-Parazite Julia. This however limits the use of Java-Parazite Julia to continuous operations in the REPL, as any invocation to a Java method within Julia code will result in an error upon evaluation of said Julia code, stating the method (representing the Java method in Julia) doesn't exist yet.

- LoadOnStartUp: This was the second approach we implemented, in particular as an idea to solve the limitation of the previous approach regarding the evaluation of Julia functions with nested calls to Java methods. In this approach, the generic function that reifies a Java Class' methods with a given name is generated whenever said class is imported to Julia (thru the jimport method we defined). When a class is jimported, ALL of it's methods are "imported" to Java, meaning all generic functions and specialized methods are imported.

\
Benchmarks were run in three different machines:

| ID | CPU | RAM | DISK |
|:---:|:---:|:---:|:---:|
| desktop | AMD Ryzen 5 5600X(65W) @ 3700/4650 Mhz | 16gb ddr4 @ 1200Mhz  | SSD |
| laptop1 | AMD Ryzen 5 2500U(15W) @ 2000/3600 Mhz | 8gb ddr4 @ 1200Mhz   | SSD |
| laptop2 | INTEL i7-8565U(15W) @ 1800/4600 Mhz    | 16gb ddr4 @ 2667 Mhz | SSD |

\
Functions Benchmarked:

| function | description |
|:---:|:---:|
| initOnDemand/StartupV | Initiates 5 Java classes with a total of 297 Java public methods | 
| regressionTestSuite | Executes 38 calls to 29 unique Java public methods |

\
Benchmark Results - *LoadOnDemand:*

| MACHINE | @time initOnDemand/StartupV() | @time regressionTestSuite() | @time regressionTestSuite() |
|:---:|:---:|:---:|:---:|
| desktop | 0.391877 seconds <br/> 1.88 M alloc: 99.001 MiB <br/> 5.00% gc time | 2.478652 seconds <br/> 9.46 M alloc: 497.463 MiB <br/> 3.11% gc time | 0.005628 seconds <br/> 6.95 k alloc: 387.375 KiB <br/> |
| laptop1 | 1.032762 seconds <br/> 1.90 M alloc: 99.742 MiB <br/> 3.33% gc time | 6.288660 seconds <br/> 9.52 M alloc: 499.990 MiB <br/> 2.52% gc time | 0.017268 seconds <br/> 6.95 k alloc: 387.375 KiB <br/> |
| laptop2 |||

\
Benchmark Results - *LoadOnStartup:*

| MACHINE | @time initOnDemand/StartupV() | @time regressionTestSuite() | @time regressionTestSuite() |
|:---:|:---:|:---:|:---:|
| desktop | 1.953634 seconds <br/> 6.23 M alloc: 317.876 MiB <br/> 2.63% gc time | 1.644794 seconds <br/> 6.88 M alloc: 364.215 MiB <br/> 7.92% gc time | 0.005735 seconds <br/> 6.00 k alloc: 337.172 KiB |
| laptop1 | 5.415532 seconds <br/> 6.57 M alloc: 331.793 MiB <br/> 2.58% gc time | 4.167729 seconds <br/> 6.93 M alloc: 366.198 MiB <br/> 2.91% gc time | 0.021237 seconds <br/> 6.00 k alloc: 337.172 KiB <br/> |
| laptop2 |||

\
Advantages and Disadvantages of each Approach:

| Approach | Advantages | Disadvantages |
|:---:|:---:|:---:|
| **LoadOnDemand** | Enough for simple sessions of Java calling in Julia's REPL, or for sessions that make heavy use of the same set of methods. | Unsuitable for sessions that use large libraries - warm up time is proportional to the amount of new methods called; <br/><br/> Java calls can't be nested in Julia code - only useful for continuous REPL operations using Java.|
| **LoadOnStartUp** | Better steady-use performance - almost the same as Julia's; <br/><br/> Java calls can be nested within Julia methods.| There's a lot of  unecessary generation of methods the programmer won't likely use in the session, since when a class is imported, all of it's public methods are generated in Julia; <br/><br/> Java classes need to be imported before evaluating Julia code using them. |

\
**Conclusions and comments:**

The implementation of LoadOnStartup provided us with an important notion we were previously lacking - the generation of the generic functions is one, but not the main source of warm-up overhead. In fact, the LoadOnStartup still took quite a bit upon the first execution of regressionTestSuite(). Even though the generic functions were already generated, the invocations of it's methods for the same time still caused major overhead. This is a sign of Julia's infamous warm up time. It's worth noting we've tested this in version 1.5.3 of Julia, and possibly, there has been some improvement in this regard, with more recent versions. Nevertheless, allowing Java method calls nested inside Julia code is a priceless advantage of the LoadOnStartUp approach, and it brings the syntax of class importing a step closer to Java's syntax.


## TESTING

To test Java-Parazite Julia:
1. Load the files into an IDE supporting Julia
2. Evaluate the totality of parazitizing.jl (for the base implementation)
3. Ensure the Java classes in statement folder are compiled
4. Execute the INIT section of execution_tests.jl in the REPL
5. Execute the WORKING - REGRESSION TEST SUITE section of execution_tests.jl in the REPL

To run a quick benchmark on Java-Parazite Julia:
1. Load the files into an IDE supporting Julia
2. Evaluate the totality of parazitizing.jl (for the base implementation)
3. Ensure the Java classes in statement folder are compiled
4. Execute the INIT section of execution_tests.jl in the REPL
5. Evaluate the regressionTestSuite() function of execution_tests.jl
6. Run the `@time regressionTestSuite()` in the REPL
NOTE: The first time the command in 6. is run, the result of the benchmark is inflated due to warm up time. - Just like Julia, Java-Parazite Julia has a significant warm up time, since it has to generate the generic functions. Running the command again and comparing the benchmark results is an interesting experiment.

## OBSERVATIONS ON JAVACALL (0.7.8)

- JavaCall 0.7.8 possible bug - wrongful primitive Java types convertion / Scenario: a Java method taking a jint from Julia to Java -> signature: public void method(int i){...} / getparametertypes(method) returns JavaObject{:int} / invoking the method with an input of type JavaObject{:int} fails / invoking the method with an input of type jint works / the bug: asking the method what it receives and passing an argument of that type doesn't work -> wrongful conversion.
- JavaCall 0.7.8 possible bug - doesn't allow Static Methods to be called with a class object as receiver??

## TODO

- <s>Fix wrongful conversion from Julia int to Java's long (due to Julia's int type being Int64, which maps to Java's long). Test: @jcall printer.compute(1, 1) should invoke public int compute(int i, int j) instead of public int compute(long i, long j).</s> Solution: there's no solution! We can do for instance Int32(1) and it converts 1 to an Int32.

- <s>Support Static Invocations.</s>

- <s>Fix wrongful formation of expression - confusion with Julia's arrays and Java's arrays.</s>

- <s>Fix wrongful convertion of parameters of type string and string arrays.</s>

- <s>Fix not being able to use static methods with a class object as receiver </s>

- <s>The verification if a method is static should be revised. - possibly use isStatic instead of getModifier</s>

- <s>Avoid method generation if corresponding generic function if already defined - performance</s>

- Multiple Dispatch as a whole is complicated, but at least support methods with Object and Object[] parameter types.

- <s>Do the due convertion of return values (add convertReturn function, call it with res = eval(expr) in the end of j(expr) function), at least for primitive types (those jcall can convert)</s>

- <s>Support methods that take arrays of other Class Objects. - Ex: public int staticMethod(Line[]) from statement.Printer</s>

- <s>If we've got two classes with the same name from different packages, it might get confused (untested)</s>

- <s>Fix bug: a non-static method in a generic function is created with the implementation receiving the first object the method was created for. so if we have printer1 and printer2 objects of Printer and the method incrementGlobalVar() was generated in Julia when called printer1.incrementGlobalVar, the implementation of the method will have printer1 as it's receiver meaning printer1.incrementGlobalVar(2) returns 2, and printer2.incrementGlobalVar(2) returns 4 (instead of 2, which would be correct)</s>

## Useful Links:

- Julia Documentation: https://docs.julialang.org/en/v1/
- JavaCall Julia library documentation: https://juliainterop.github.io/JavaCall.jl/index.html
- JavaCall Julia library github page: https://github.com/JuliaInterop/JavaCall.jl
- Similar Project: Julia parazitizing Python: https://github.com/JuliaPy/PyCall.jl
- Similar Project: Lisp Syntax in Julia: https://github.com/swadey/LispSyntax.jl
