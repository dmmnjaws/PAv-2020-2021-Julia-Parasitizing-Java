# PAv-2020-2021-Julia-Parasitizing-Java

## NOTES

- One of our main focuses is to not compromise any of Julia's semantics in order to allow invocations to the JVM from Julia.


## Notes on JavaCall (0.7.8)

### BUGS:  
- JavaCall 0.7.8 bug - wrongful primitive Java types convertion / Scenario: a Java method taking a jint from Julia to Java -> signature: public void method(int i){...} / getparametertypes(method) returns JavaObject{:int} / invoking the method with an input of type JavaObject{:int} fails / invoking the method with an input of type jint works / the bug: asking the method what it receives and passing an argument of that type doesn't work -> wrongful conversion.
- JavaCall 0.7.8 bug - having jlong as Int64 seems to be a bad idea, since Julia's default ints are Int64, which makes them incompatible with Java's. Same goes for Float32/64. As a consequence, this requires extra effort from the programmer in the return and argument type conversions.

## TODO

- Fix wrongful conversion from Julia int to Java's long (due to Julia's int type being Int64, which maps to Java's long). Test: @jcall printer.compute(1, 1) should invoke public int compute(int i, int j) instead of public int compute(long i, long j).

- <s>Support Static Invocations.</s>

- <s>Fix wrongful formation of expression - confusion with Julia's arrays and Java's arrays.</s>

- Fix wrongful convertion of parameters of type string.

## Useful Links:

- Julia Documentation: https://docs.julialang.org/en/v1/
- JavaCall Julia library documentation: https://juliainterop.github.io/JavaCall.jl/index.html
- JavaCall Julia library github page: https://github.com/JuliaInterop/JavaCall.jl
- Similar Project: Julia parazitizing Python: https://github.com/JuliaPy/PyCall.jl
- Similar Project: Lisp Syntax in Julia: https://github.com/swadey/LispSyntax.jl
