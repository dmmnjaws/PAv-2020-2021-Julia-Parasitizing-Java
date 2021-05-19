# PAv-2020-2021-Julia-Parasitizing-Java

## NOTES

- One of our main focuses is to not compromise any of Julia's semantics in order to allow invocations to the JVM from Julia.
- Since for each new method, we generate all generic functions for that receiver when we call ir the first time, our Java-Parazite-Julia has a bigger start up time.

## LIMITATIONS
- Java supports invocation of static methods in null objects, because these still have a defined type. (ex: Math math = null is of type Math). However we don't support this in our implementation of Java-Parazite-Julia, because we can't (found no way to...), assign a DataType to a nothing in Julia, like we can assign a Class to a null in Java.

## Notes on JavaCall (0.7.8)

### POSSIBLE BUGS:  
- JavaCall 0.7.8 bug - wrongful primitive Java types convertion / Scenario: a Java method taking a jint from Julia to Java -> signature: public void method(int i){...} / getparametertypes(method) returns JavaObject{:int} / invoking the method with an input of type JavaObject{:int} fails / invoking the method with an input of type jint works / the bug: asking the method what it receives and passing an argument of that type doesn't work -> wrongful conversion.
- JavaCall 0.7.8 bug - having jlong as Int64 seems to be a bad idea, since Julia's default ints are Int64, which makes them incompatible with Java's. Same goes for Float32/64. As a consequence, this requires extra effort from the programmer in the return and argument type conversions.
- Static Methods can't be called with a class object as receiver??

## TODO

- <s>Fix wrongful conversion from Julia int to Java's long (due to Julia's int type being Int64, which maps to Java's long). Test: @jcall printer.compute(1, 1) should invoke public int compute(int i, int j) instead of public int compute(long i, long j).</s> Solution: there's no solution! We can do for instance Int32(1) and it converts 1 to an Int32.

- <s>Support Static Invocations.</s>

- <s>Fix wrongful formation of expression - confusion with Julia's arrays and Java's arrays.</s>

- <s>Fix wrongful convertion of parameters of type string and string arrays.</s>

- >s>Fix not being able to use static methods with a class object as receiver </s>

- <s>The verification if a method is static should be revised. - possibly use isStatic instead of getModifier</s>

- <s>Avoid method generation if corresponding generic function if already defined - performance</s>

- Multiple Dispatch as a whole is complicated, but at least support methods with Object and Object[] parameter types.

- Do the due convertion of return values (add convertReturn function, call it with res = eval(expr) in the end of j(expr) function), at least for primitive types (those jcall can convert)

- UNTESTED: Methods that take arrays of other Class Objects

## Useful Links:

- Julia Documentation: https://docs.julialang.org/en/v1/
- JavaCall Julia library documentation: https://juliainterop.github.io/JavaCall.jl/index.html
- JavaCall Julia library github page: https://github.com/JuliaInterop/JavaCall.jl
- Similar Project: Julia parazitizing Python: https://github.com/JuliaPy/PyCall.jl
- Similar Project: Lisp Syntax in Julia: https://github.com/swadey/LispSyntax.jl
