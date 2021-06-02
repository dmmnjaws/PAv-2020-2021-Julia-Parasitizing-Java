# PAv-2020-2021-Julia-Parasitizing-Java

## PROJECT STRUCTURE

- **Java-Parazite-Julia-LoadOnDemand.jl** - file containing the Julia code of the LoadOnDemand approach of Java-Parazite Julia

- **Java-Parazite-Julia-LoadOnStartUp.jl** - file containing the Julia code of the LoadOnStartUp approach of Java-Parazite Julia

- **Java-Parazite-Julia-LoadOnStartUp-Extended.jl** - same as above but used to experiment with extensions (*everything done after the June the 2nd*), these are the differences:
  - Addition of a generateSuperTypes function that for a given class returns all of it's Superclasses in Java

- **execution_tests.jl** - file containing all Julia code related to tests

- **/statement folder** - folder containing Java classes for testing (recompile these if needed)

- **/util folder** - folder containing aiding Java code

<br/>

## GENERAL NOTES

- One of our main focuses is to not compromise any of Julia's semantics in order to allow invocations to the JVM from Julia.

- Since for each new method, we generate all generic functions for that receiver when we call it the first time, our Java-Parazite-Julia has a bigger start up time.

- With time we realized it would be interesting to explore two alternatives to the generic-function generation of Java-Parazite Julia: One that generates the methods on-demand (when a method is called for the first time), and another that generates the methods upon startup (similarly to Java, imports (jimport) should be done in the beginning).

- All development, testing and benchmarking were conducted in Julia 1.5.3 and Java 1.8.0

<br/>

## LIMITATIONS

- Java supports invocation of static methods in null objects, because these still have a defined type. (ex: Math math = null is of type Math). However we don't support this in our implementation of Java-Parazite-Julia, because we can't (found no way to...), assign a DataType to a nothing in Julia, like we can assign a Class to a null in Java. (*Both LoadOnDemand and LoadOnStartup feature this limitation.*)

- Using a @jcall call nested in a Julia method unfortunately isn't possible. Since we don't generate all generic functions upon import of a class, but only upon calling, on demand, Julia will not be able to evaluate a @jcall call, and will warn the user that it's trying to call a method not yet defined. This is something we unfortunately didn't predict early on, and fixing it requires a remodeling of our entire code. A possible approach would be for the generic functions to be pre-loaded, via a mechanism involving static import as the first lines of a Java-Parazite Julia program, just like it's done in Java, substituting the current loaded-on-demand approach. - This renders Java-Parazite Julia only useful for simple realtime calls to Java, for now... (*As of the 29th of May, this limitation was **solved** by the LoadOnStartup approach, therefore it's exclusive to the LoadOnDemand approach.*)

- Class hierarchies are not recognized, for instance: A method that takes an Object, isn't able to be called with a String. (But it should.) Even though an extention to support this wasn't implemented yet, our approach to generic functions had the accomodation of this feature in mind, requiring the aditional reification of the Java class hierarchies, in Julia. If such reification exists, Julia should be able to select a method from a given generic function accordingly (and even making use of Mulitple Dispatch) (*Both LoadOnDemand and LoadOnStartup feature this limitation.*)

- Importing Java packages instead of explicit Java classes onto Julia is not possible. (*Both LoadOnDemand and LoadOnStartup feature this limitation.*)

<br/>

## COMPARING LoadOnDemand and LoadOnStartup

**Brief summary of the two approaches:**

- **LoadOnDemand**: This was the first approach we implemented. In this approach, the generic function that reifies a Java Class' methods with a given name is generated whenever a method with said name and said class as receiver is invoked using Java-Parazite Julia. This however limits the use of Java-Parazite Julia to continuous operations in the REPL, as any invocation to a Java method within Julia code will result in an error upon evaluation of said Julia code, stating the method (representing the Java method in Julia) doesn't exist yet.

- **LoadOnStartUp**: This was the second approach we implemented, in particular as an idea to solve the limitation of the previous approach regarding the evaluation of Julia functions with nested calls to Java methods. In this approach, the generic function that reifies a Java Class' methods with a given name is generated whenever said class is imported to Julia (through the jimport method we defined). When a class is jimported, ALL of it's methods are "imported" to Java, meaning all generic functions and specialized methods are imported.

We ran benchmarks in order to study the impact of both approaches in performance.


Benchmarks were run in three different machines:

| ID | CPU | RAM | DISK |
|:---:|:---:|:---:|:---:|
| desktop | AMD Ryzen 5 5600X(65W) @ 3700/4650 Mhz 6cores/12threads | 16gb ddr4 @ 1200Mhz  | SSD |
| laptop1 | AMD Ryzen 5 2500U(15W) @ 2000/3600 Mhz 4cores/8threads | 8gb ddr4 @ 1200Mhz   | SSD |
| laptop2 | INTEL i5-7200U(15W) @ 2400/3100 Mhz 2cores/4threads   | 8gb ddr4 @ 1200Mhz | SSD |


Functions Benchmarked:

| FUNCTION | DESCRIPTION |
|:---:|:---:|
| initOnDemand/StartupV | Initiates 5 Java classes with a total of 297 Java public methods |
| regressionTestSuite | Executes 38 calls to 27 unique Java public methods |

**NOTE:** The initOnDemandV() and initOnStartupV() differ solely in the syntax and semantic of imports, which differs from the LoadOnDemand to the LoadOnStartup approach.


Benchmark Results - *LoadOnDemand:*

| MACHINE | @time initOnDemandV() | @time regressionTestSuite() | @time regressionTestSuite() |
|:---:|:---:|:---:|:---:|
| desktop | 0.391877 seconds <br/> 1.88 M alloc: 99.001 MiB <br/> 5.00% gc time | 2.478652 seconds <br/> 9.46 M alloc: 497.463 MiB <br/> 3.11% gc time | 0.005628 seconds <br/> 6.95 k alloc: 387.375 KiB <br/> |
| laptop1 | 1.032762 seconds <br/> 1.90 M alloc: 99.742 MiB <br/> 3.33% gc time | 6.288660 seconds <br/> 9.52 M alloc: 499.990 MiB <br/> 2.52% gc time | 0.017268 seconds <br/> 6.95 k alloc: 387.375 KiB <br/> |
| laptop2 | 1.206014 seconds <br/> 1.88 M alloc: 99.001 MiB <br/> 3.61% gc time | 7.598155 seconds <br/> 9.45 M alloc: 497.448 MiB <br/> 2.41% gc time | 0.027408 seconds <br/> 6.95 k alloc: 387.375 KiB |


Benchmark Results - *LoadOnStartup:*

| MACHINE | @time initOnStartupV() | @time regressionTestSuite() | @time regressionTestSuite() |
|:---:|:---:|:---:|:---:|
| desktop | 1.953634 seconds <br/> 6.23 M alloc: 317.876 MiB <br/> 2.63% gc time | 1.644794 seconds <br/> 6.88 M alloc: 364.215 MiB <br/> 7.92% gc time | 0.005735 seconds <br/> 6.00 k alloc: 337.172 KiB |
| laptop1 | 5.415532 seconds <br/> 6.57 M alloc: 331.793 MiB <br/> 2.58% gc time | 4.167729 seconds <br/> 6.93 M alloc: 366.198 MiB <br/> 2.91% gc time | 0.021237 seconds <br/> 6.00 k alloc: 337.172 KiB <br/> |
| laptop2 | 6.162297 seconds <br/> 6.22 M alloc: 316.949 MiB <br/> 2.04% gc time | 5.571538 seconds <br/> 6.87 M alloc: 363.601 MiB <br/> 5.04% gc time | 0.024880 seconds <br/> 6.00 k alloc: 337.172 KiB |

**NOTE:** It's worth noting that, with LoadOnStartUp, running the initiation a second time won't wield the same values - when a Java class is imported, the generic functions corresponding to it's public methods are only generated if they weren't generated before...

Advantages and Disadvantages of each Approach:

| APPROACH | ADVANTAGES | DISADVANTAGES |
|:---:|:---:|:---:|
| **LoadOnDemand** | Enough for simple sessions of Java calling in Julia's REPL, or for sessions that make heavy use of the same set of methods. | Unsuitable for sessions that use large libraries - warm up time is proportional to the amount of new methods called; <br/><br/> Java calls can't be nested in Julia code - only useful for continuous REPL operations using Java.|
| **LoadOnStartUp** | Better steady-use performance - almost the same as Julia's; <br/><br/> Java calls can be nested within Julia methods; <br/><br/> Closer to Java's syntax/semantics. | There's a lot of  unecessary generation of methods the programmer won't likely use in the session, since when a class is imported, all of it's public methods are generated in Julia; <br/><br/> Java classes need to be imported before evaluating Julia code using them. |


**Conclusions and comments:**

The implementation of LoadOnStartup provided us with an important notion we were previously lacking - the generation of the generic functions is one, but not the main source of warm-up overhead. In fact, the LoadOnStartup still took quite a bit of time upon the first execution of regressionTestSuite(). Even though the generic functions were already generated, the invocations of it's methods for the first time still caused major overhead. This is a sign of Julia's infamous warm up time. It's worth noting we've tested this in version 1.5.3 of Julia, and possibly, there has been some improvement in this regard, with more recent versions. Nevertheless, allowing Java method calls nested inside Julia code is a priceless advantage of the LoadOnStartUp approach, and it brings the syntax of class importing a step closer to Java's syntax/semantics.

**IMPORTANT NOTE: It's worth noting that, after the conception of LoadOnStartUp, all posterior development was done on top of this approach, meaning LoadOnDemand remained unupdated. Nevertheless, all base tests included in the Regression Test Suite work on both approaches. However, we strongly encourage further testing to be done on the LoadOnStartUp approach.**

<br/>

## TESTING

### OUR TEST SUITE:

The file execution_tests.jl features a full test suite that tests the following quirks of Java-Parazite Julia:
- call to Java methods taking jint, jlong, jfloat, jdouble, jchar, (Julia) Char, jboolean, (Julia) Bool, jshort, jbyte as parameters
- call to Java methods taking arrays of all primitives listed above
- call to Java methods taking Strings as parameters
- call to Java methods taking arrays of String as parameters
- call to polymorphic Java methods with same receiver types
- call to polymorphic Java methods with different receiver types
- call to static Java methods from an instance object receiver
- call to static Java methods from a non-instantiated class receiver
- call to Java methods taking other class instances as parameters
- call to Java methods taking arrays of instances of other classes as parameters
- call to Java methods that alter a global variable in a Java object,
- call to the same Java method that alters global variables in a Java object, in two different Java objects to verify each object is being updated independently of the other

The tests can be ran in both the LoadOnDemand and LoadOnStartUp versions, but be mindfull that each approach requires slightly different initialization - The default way of importing Java classes into Julia provided by JavaCall will not work with the LoadOnStartUp approach. We strongly recommend following the steps provided in the beginning of the execution_test.jl file.

### MANUAL:

We provide a manual for each approach, for general use or specialized testing.

**LoadOnDemand**
- Loading a Java class into Julia:
  - Class = JavaCall.jimport("package.Class")
- Creating an instance of said class:
  - classInstance = Class(())
- Invoking a Java method:
  - @jcall classInstance.methodName(argument1, argument2, ...)
  - res = @jcall classInstance.methodName(argument1, argument2, ...)
- Additionaly to invoke a static Java method:
  - @jcall Class.methodName(argument1, argument2, ...)
  - res = @jcall Class.methodName(argument1, argument2, ...)

**LoadOnStartup**
- Loading a Java class into Julia:
  - Class = @jimport "package.Class"
- Creating an instance of said class:
  - classInstance = Class(())
- Invoking a Java method:
  - @jcall classInstance.methodName(argument1, argument2, ...)
  - res = @jcall classInstance.methodName(argument1, argument2, ...)
- Additionaly to invoke a static Java method:
  - @jcall Class.methodName(argument1, argument2, ...)
  - res = @jcall Class.methodName(argument1, argument2, ...)

<br/>

## STUFF WE DIDN'T EXPLORE

There were a few things we choose to not explore due to time constraints, or that we downright forgot to explore. These are things that we would like to revisit in future work.

- **Java Constructors** - We did not explore the "implementation" of Java constructors in Julia. We're not aware if they work as intended or not, other than parameter-less constructors (these work as offered by default by JavaCall). This was something that came to mind during a brainstorm session close to the deadline, therefore constructors with parameters remain untested.

- **Java VarArgs Methods** - Like Java Constructors, we did not explore the convertion of Java VarArgs methods into Julia methods, and we're not aware if they work as intended or not in our current implementation. This is something we had in mind since the beginning but the idea fell behind in the midst of other priorities. The generation/call of Julia methods corresponding to Java VarArg Methods remains untested.
<br/><br/>

- **Supertyping and Multiple Dispatch** - Supertyping and Multiple Dispatch pose a different kind of challenge. Even though this section is called "STUFF WE DIDN'T EXPLORE", we did explore these concepts loosely and came up with some conclusions (mainly resulting from experimentation and discussion with professor António). **Supertyping** alone, or ideally, reifying the Java class hierarchies in Julia, poses a challenge - in Java for a given class, it's superclasses can be instantiated, however, in Julia, this isn't the case - a type in Julia, for instance, Int64 can be instantiated, but it's supertypes, Signed, Integer, Real, Number and Any can't be instantiated on their own. This of course represents a radical disparity between Java's Semantic and Julia's Semantic. **Multiple Dispatch** could make use of **Supertyping** if possible, but another challenge emerges - In Java, multiple extension is possible, since a class can inherit from another class and implement multiple interfaces. However, in Julia, this is impossible - In Julia, a type can only have one supertype, therefore, for instance, calling supertypes(Int64) returning Signed, Integer, Real, Number and Any, actually returns the types, in order, belonging to an unidirectional chain of supertypes, with Int64 being it's only "leaf". Again, a radical disparity between Java and Julia's Semantic. However, it could be interesting to explore this in future work, in particular, by starting small... Even though Java has multiple extension of interfaces, it only supports single inheritance of classes (a class can only have up to one superclass), which is closer to Julia's singular supertyping, and could be a starting point (ignoring interfase hiearchy, for a start). Nevertheless, the challenge prompted by **Supertyping** emerges once again...

<br/>

# DEVELOPMENT NOTES

## OBSERVATIONS ON JAVACALL (0.7.8)

- JavaCall 0.7.8 possible bug - wrongful primitive Java types convertion / Scenario: a Java method taking a jint from Julia to Java -> signature: public void method(int i){...} / getparametertypes(method) returns JavaObject{:int} / invoking the method with an input of type JavaObject{:int} fails / invoking the method with an input of type jint works / the bug: asking the method what it receives and passing an argument of that type doesn't work -> wrongful conversion?
- JavaCall 0.7.8 possible bug - doesn't allow Static Methods to be called with a class object as receiver??

<br/>

## TODO

- <s>Fix wrongful conversion from Julia int to Java's long (due to Julia's int type being Int64, which maps to Java's long). Test: @jcall printer.compute(1, 1) should invoke public int compute(int i, int j) instead of public int compute(long i, long j).</s> (*EDIT: Solution: We can do for instance Int32(1) and it converts 1::Int64 to 1::Int32.*)

- <s>Support Static Invocations.</s>

- <s>Fix wrongful formation of expression - confusion with Julia's arrays and Java's arrays.</s>

- <s>Fix wrongful convertion of parameters of type string and string arrays.</s>

- <s>Fix not being able to use static methods with a class object as receiver </s>

- <s>The verification if a method is static should be revised. - possibly use isStatic instead of getModifier</s>

- <s>Avoid method generation if corresponding generic function if already defined - performance</s>

- Multiple Dispatch as a whole is complicated, but at least support methods with Object and Object[] parameter types. (*EDIT: Discussed in the section "STUFF WE DIDN'T EXPLORE"*)

- <s>Do the due convertion of return values (add convertReturn function, call it with res = eval(expr) in the end of j(expr) function), at least for primitive types (those jcall can convert)</s>

- <s>Support methods that take arrays of other Class Objects. - Ex: public int staticMethod(Line[]) from statement.Printer</s>

- <s>If we've got two classes with the same name from different packages, it might get confused (untested)</s>

- Support Java VarAgrs methods (uncertain, test if they work in current implementation) (*EDIT: Discussed in the section "STUFF WE DIDN'T EXPLORE"*)

- <s>Fix bug: a non-static method in a generic function is created with the implementation receiving the first object the method was created for. so if we have printer1 and printer2 objects of Printer and the method incrementGlobalVar() was generated in Julia when called printer1.incrementGlobalVar, the implementation of the method will have printer1 as it's receiver meaning printer1.incrementGlobalVar(2) returns 2, and printer2.incrementGlobalVar(2) returns 4 (instead of 2, which would be correct)</s>

<br/>

## Useful Links:

- Julia Documentation: https://docs.julialang.org/en/v1/
- JavaCall Julia library documentation: https://juliainterop.github.io/JavaCall.jl/index.html
- JavaCall Julia library github page: https://github.com/JuliaInterop/JavaCall.jl
- Similar Project: Julia parazitizing Python: https://github.com/JuliaPy/PyCall.jl
- Similar Project: Lisp Syntax in Julia: https://github.com/swadey/LispSyntax.jl
