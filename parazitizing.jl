function j(expr)
    try
        if !((expr.head == :call) && (expr.args[1].head == :.))
            throw(ArgumentError("Usage: @jcall receiver.method(args...)"))
        end
    catch LoadError
        throw(ArgumentError("Usage: @jcall receiver.method(args...)"))
    end

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
        push!(argumentTypes, convertPrimitive(typeof(argument)))
        push!(argumentValues, argument)
    end
    argumentTypes = tuple(argumentTypes...)
    argumentValues = tuple(argumentValues...)
    println("\n\nmethod's parameter types")
    show(argumentTypes)
    println("\n\npassed parameter values:")
    show(argumentValues)
    println("\n")

    try
        jcall(receiver, methodName, JObject, argumentTypes, argumentValues...)
    catch JavaCallError
        jcall(receiver, methodName, Nothing, argumentTypes, argumentValues...)
    end
end

macro jcall(expr)
    j(expr)
end

function convertPrimitive(primitive::Type{JavaObject{T}} where T)
    if primitive == JavaObject{:int}
        jint
    elseif primitive == JavaObject{:long}
        jlong
    elseif primitive == JavaObject{:float}
        jfloat
    elseif primitive == JavaObject{:double}
        jdouble
    elseif primitive == JavaObject{:char}
        jchar
    elseif primitive == JavaObject{:boolean}
        jboolean
    else
        primitive
    end
end

# THESE EXAMPLES ALLOW US TO UNDERSTAND A BIT BETTER THE SYNTAX OF JULIA/JAVACALL AND THE LIMITATIONS OF JAVACALL

# Given a Line and a Brush, and the parameter types Shape and Brush
# jcall doesn't choose the most specific method, so it chooses according solely to the parameterTypes
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
paramTypeTuple = (param1GeneralizationType, param2Type)
paramValueTuple = [param1, param2]
jcall(printer, "draw", returnType, paramTypeTuple, param1, param2)

# Given a Line and a Crayon, and same those parameterTypes
# jcall, in the absence of a method taking Line and Crayon, doesn't choose the "next best method"
param1Type = JavaCall.jimport("statement.Line")
param2Type = JavaCall.jimport("statement.Crayon")
param1 = param1Type(())
param2 = param2Type(())
paramTypeTuple = (param1Type, param2Type)
jcall(printer, "draw", returnType, paramTypeTuple, param1, param2)

# Given a Line and a Crayon, and the parameter Types Line and Brush
# jcall, calls a method taking Line and Brush, and accepts Crayon as Brush
param1Type = JavaCall.jimport("statement.Line")
param2Type = JavaCall.jimport("statement.Brush")
param1 = param1Type(())
param2 = param2Type(())
paramTypeTuple = (param1Type, param2Type)
jcall(printer, "draw", returnType, paramTypeTuple, param1, param2)

# JavaCall 0.7.8 bug - wrongful primitive Java types convertion:
method = first(listmethods, "compute")
methodreturntype = JavaCall.jimport(getname(getreturntype(method)))
methodparametertypes = tuple(map(x-> JavaCall.jimport(getname(x)), getparametertypes(method))...)
methodname = jcall(method, "getName"; JString, (),)
# this fails because returntype and parametertypes are JavaObject{:int}, which are aparently not the same as jint = Int32:
jcall(printer, methodname, methodreturntype, methodparametertypes, 1, 1)
# this works:
jcall(printer, methodname, jint, (jint, jint), 1, 1)
