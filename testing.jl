using JavaCall
JavaCall.init(["-Xmx512M", "-Djava.class.path=$(@__DIR__)"])
JMath = @jimport java.lang.Math
jmath = JMath(())
JHashMap = @jimport java.util.HashMap
jhashmap = JHashMap(())
jhashmap = makeInstance(JHashMap)

struct JavaValue
    ref::JavaObject
    methods::Dict
end

# struct JavaStaticValue
#     ref::Type{JavaObject{T}} where T
#     methods::Dict
# end

Base.show(io::IO, javaValue::JavaValue) =
    show(io, getfield(javaValue, :ref))
    println("")

# Base.show(io::IO, javaStaticValue::JavaStaticValue) =
#     show(io, getfield(javaStaticValue, :ref))
#     println("")

function Base.getproperty(javaValue::JavaValue, symbol::Symbol)
    if symbol == Symbol(String("ref"))
        getfield(javaValue, :ref)
    elseif symbol == Symbol(String("methods"))
        getfield(javaValue, :methods)
    else
        getfield(javaValue, :methods)[symbol](getfield(javaValue, :ref))
    end
end

# Base.getproperty(javaStaticValue::JavaStaticValue, symbol::Symbol) =
#     getfield(javaStaticValue, :methods)[symbol](getfield(javaStaticValue, :ref))

function makeInstance(type::DataType, args...)
    instance = type((args));
    JavaValue(instance, makeMethodDictionary(instance))
end

# function makeMethodDictionary(instance::JavaObject)
#     listOfMethods = listmethods(instance)
#     methodDictionary = Dict()
#     for method::JMethod in listOfMethods
#         methodName = Symbol(getname(method))
#         methodDictionary[methodName] = (method) -> (receiver) -> (args...) -> (
#             methodToInvoque = method;
#             show("method: " * method);
#             println("");
#             show("receiver: " * receiver);
#             println("");
#             show("arguments: " * args);
#             println("");
#             invocation = jcall(receiver, methodToInvoque, args);
#             JavaValue(invocation, makeMethodDictionary(invocation))
#         )
#     end
#     methodDictionary
# end

function makeMethodDictionary(instance::JavaObject)
    listOfMethods = listmethods(instance)
    dict = Dict()
    for i::JMethod in listOfMethods
        methodName = Symbol(getname(i))
        methodReturnType = typeof(getreturntype(i))
        methodParameterTypes = []
        for i in getparametertypes(i)
            push!(methodParameterTypes, JObject)
            # push!(methodParameterTypes, typeof(i))
            # show(methodParameterTypes)
            # println("")
        end
        methodParameterTypes = tuple(methodParameterTypes...)
        dict[methodName] =
                (receiver) -> (args...) -> (
            show(receiver);
            println("");
            show(args);
            println("");
            show(methodParameterTypes);
            println("");
            show(methodReturnType);
            println("");
            JavaValue(jcall(receiver, getname(i), methodReturnType, methodParameterTypes, args),
            makeMethodDictionary(jcall(receiver, getname(i), methodReturnType, methodParameterTypes, args))))
        # show(dict[methodName])
        # println("")
    end
    dict
end

jcallExpression = :(jcall(receiver, methodName, returnType, parameterTypes, args...))

function Base.getproperty(receiver::JavaObject, symbol::Symbol)
    println(stdin)
end

function j(expr)
    receiver = @eval $(first(first(expr.args).args))
    println("\nmethod's receiver:")
    show(receiver)

    methodName = SubString(string(last(first(expr.args).args)), 2, length(string(last(first(expr.args).args))))
    println("\n\nmethod's name:")
    show(methodName)

    arguments = deepcopy(expr.args)
    popfirst!(arguments)
    argumentTypes = []
    argumentValues = []
    for argSymbol in arguments
        argument = @eval $(argSymbol)
        push!(argumentTypes, typeof(argument))
        push!(argumentValues, argument)
    end
    argumentTypes = tuple(argumentTypes...)
    argumentValues = tuple(argumentValues...)
    println("\n\nmethod's parameter types")
    show(argumentTypes)
    println("\n\npassed parameter values:")
    show(argumentValues)
    println("\n")

    # jcall(receiver, methodName, JObject, argumentTypes, argumentValues...)
    "draw what where"
end

# Proof that JavaCall doesn't take care of Multiple Dispatch
# Given a Line and a Brush, but generalizing the parameter types of draw for Shape and Brush
# jcall doesn't choose the most specific method
using JavaCall
JavaCall.init(["-Xmx512M", "-Djava.class.path=$(@__DIR__)"])
Printer = JavaCall.jimport("statement.Printer")
printer = Printer(())
allMethods = listmethods(printer, "draw")
returnType = JavaCall.jimport(getname(getreturntype(last(allMethods))))
parameterTypes = getparametertypes(last(allMethods))
param1GeneralizationType = JavaCall.jimport(getname(first(parameterTypes)))
param1SpecificationType = JavaCall.jimport("statement.Line")
param1 = param1SpecificationType(())
param2Type = JavaCall.jimport(getname(last(parameterTypes)))
param2 = param2Type(())
paramTuple = (param1GeneralizationType, param2Type)
jcall(printer, "draw", returnType, paramTuple, param1, param2)
expr = :(printer.draw(param1, param2))
