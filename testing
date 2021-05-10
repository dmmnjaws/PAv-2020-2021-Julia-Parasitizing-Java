using JavaCall
JavaCall.init(["-Xmx128M"])
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
