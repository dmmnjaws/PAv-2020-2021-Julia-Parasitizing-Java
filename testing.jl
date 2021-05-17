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
paramTypeTuple = (param1GeneralizationType, param2Type)
paramValueTuple = [param1, param2]
jcall(printer, "draw", returnType, paramTypeTuple, param1, param2)
expr = :(printer.draw(param1, param2))

paramTypeTuple = (JObject, JString, Array{JObject, 1})
javaDispatcher = JavaCall.jimport("selector.UsingMultipleDispatchExtended")
invokeMethod = first(listmethods(javaDispatcher))
jcall(javaDispatcher, "invoke", JObject, paramTypeTuple, printer, "draw", paramValueTuple)

j_u_arrays = @jimport java.util.Arrays
jcall(j_u_arrays, "binarySearch", jint, (Array{jint,1}, jint), [10,20,30,40,50,60], 40)
jcall(j_u_arrays, "binarySearch", jint, (Array{JObject,1}, JObject), ["123","abc","uvw","xyz"], "uvw")

# JavaCall 0.7.8 bug - wrongful primitive Java types convertion:
method = first(listmethods, "compute")
methodreturntype = JavaCall.jimport(getname(getreturntype(method)))
methodparametertypes = tuple(map(x-> JavaCall.jimport(getname(x)), getparametertypes(method))...)
methodname = jcall(method, "getName"; JString, (),)
# this fails because returntype and parametertypes are JavaObject{:int}, which are aparently not the same as jint = Int32:
jcall(printer, methodname, methodreturntype, methodparametertypes, 1, 1)
# this works:
jcall(printer, methodname, jint, (jint, jint), 1, 1)

function convertPrimitive(primitive)
    if primitive == JavaObject{:int} || primitive == Int32
        jint
    elseif primitive == JavaObject{:long} || primitive == Int64
        jlong
    elseif primitive == JavaObject{:float} || primitive == Float32
        jfloat
    elseif primitive == JavaObject{:double} || primitive == Float64
        jdouble
    elseif primitive == JavaObject{:char} || primitive == UInt16
        jchar
    elseif primitive == JavaObject{:boolean} || primitive == UInt8
        jboolean
    elseif primitive == JavaObject{:short} || primitive == Int16
        jshort
    elseif primitive == JavaObject{:byte} || primitive == Int8
        jbyte
    elseif primitive == JavaObject{Symbol("int[]")} || primitive == Array{Int32, 1}
        exprArrayTypeBuilder(:Int32)
    elseif primitive == JavaObject{Symbol("long[]")} || primitive == Array{Int64, 1}
        exprArrayTypeBuilder(:Int64)
    elseif primitive == JavaObject{Symbol("float[]")} || primitive == Array{Float32, 1}
        exprArrayTypeBuilder(:Float32)
    elseif primitive == JavaObject{Symbol("double[]")} || primitive == Array{Float64, 1}
        exprArrayTypeBuilder(:Float64)
    elseif primitive == JavaObject{Symbol("char[]")} || primitive == Array{UInt16, 1}
        exprArrayTypeBuilder(:UInt16)
    elseif primitive == JavaObject{Symbol("boolean[]")} || primitive == Array{UInt8, 1}
        exprArrayTypeBuilder(:UInt8)
    elseif primitive == JavaObject{Symbol("short[]")} || primitive == Array{Int16, 1}
        exprArrayTypeBuilder(:Int16)
    elseif primitive == JavaObject{Symbol("byte[]")} || primitive == Array{Int8, 1}
        exprArrayTypeBuilder(:Int8)
    elseif primitive == Nothing
        Nothing
    else
        expr = importExprBuilder(getImportName(primitive))
        eval(expr)
        expr.args[1]
    end
end

function j(expr)
    try
        if !((expr.head == :call) && (expr.args[1].head == :.))
            throw(ArgumentError("Usage: @jcall receiver.method(args...)"))
        end
    catch LoadError
        throw(ArgumentError("Usage: @jcall receiver.method(args...)"))
    end

    receiver = first(first(expr.args).args)
    methodName = string(SubString(string(last(first(expr.args).args)), 2, length(string(last(first(expr.args).args)))))
    arguments = deepcopy(expr.args)
    popfirst!(arguments)
    methodInterpreter((@eval $(receiver)), methodName)
    expr = :()
    expr.head = :call
    push!(expr.args, Symbol(methodName))
    push!(expr.args, Symbol(receiver))
    for arg in arguments
        push!(expr.args, arg)
    end
    eval(expr)
end

macro jcall(expr)
    j(expr)
end

function methodInterpreter(receiver, methodName::String)
    methods = listmethods(receiver, methodName)
    for method::JMethod in methods

        # TODO: check if method is static. If method is static, two methods for the generic function should exist:
        # 1. one taking the type of the receiver object, as usual,
        # 2. the other taking the type Type{JavaObject{T}} where T is the type of the receiver (static)
        # ex:
        # 1. binarySearch(::JavaObject{Symbol("java.util.Arrays")}, ::Array{Int64,1}, ::Int64) at none:0
        # 2. binarySearch(::Type{JavaObject{Symbol("java.util.Arrays")}}, ::Array{Int64,1}, ::Int64) at none:0

        parameterTypes = getparametertypes(method)
        parameterTypes = tuple(map(x -> eval(convertPrimitive(JavaCall.jimport(getname(x)))), parameterTypes)...)
        returnType = convertPrimitive(JavaCall.jimport(getname(getreturntype(method))))
        methodName = jcall(method, "getName", JString, (),)
        exprSignature = exprSignatureBuilder(receiver, methodName, parameterTypes)
        exprImplementation = exprImplementationBuilder(receiver, methodName, returnType, parameterTypes)
        expression = exprBuilder(exprSignature, exprImplementation)
        eval(expression)
    end
end

function exprSignatureBuilder(receiver, methodName::String, parameterTypes)
    expr = :()
    expr.head = :call
    push!(expr.args, Symbol(methodName))
    i = "a"
    push!(expr.args, exprParameterBuilder(Symbol("receiver"), Symbol(convertPrimitive(receiver))))
    for parameterType::DataType in parameterTypes
        retifiedType = convertPrimitive(parameterType)
        push!(expr.args, exprParameterBuilder(Symbol(i), retifiedType))
        i = i * "a"
    end
    expr
end

function exprImplementationBuilder(receiver, methodName::String, returnType, parameterTypes)
    expr = :()
    expr.head = Symbol("block")
    push!(expr.args, LineNumberNode)
    mainexpr = :(jcall($(receiver), $(methodName), $(returnType), $(parameterTypes)))
    i = "a"
    for parameterType::DataType in parameterTypes
        push!(mainexpr.args, Symbol(i))
        i = i * "a"
    end
    push!(expr.args, mainexpr)
    expr
end

function exprParameterBuilder(parameterName::Symbol, parameterType)
    expr = :()
    expr.head = :(::)
    push!(expr.args, parameterName)
    push!(expr.args, parameterType)
    expr
end

function exprBuilder(exprSignature::Expr, exprImplementaiton::Expr)
    expr = :()
    expr.head = :(=)
    push!(expr.args, exprSignature)
    push!(expr.args, exprImplementaiton)
    expr
end

function exprArrayTypeBuilder(type::Symbol)
    expr = :()
    expr.head = :curly
    push!(expr.args, :Array)
    push!(expr.args, type)
    push!(expr.args, 1)
    expr
end

function importExprBuilder(importName::String)
    className = last(split(importName, "."))
    expr = :()
    expr.head = :(=)
    push!(expr.args, Symbol(className))
    assignmentExpr = :()
    assignmentExpr.head = :call
    assignmentExprCall = :()
    assignmentExprCall.head = :(.)
    push!(assignmentExprCall.args, Symbol("JavaCall"))
    quoteNode = QuoteNode(Symbol("jimport"))
    push!(assignmentExprCall.args, quoteNode)
    push!(assignmentExpr.args, assignmentExprCall)
    push!(assignmentExpr.args, importName)
    push!(expr.args, assignmentExpr)
    expr
end

function getImportName(foo)::String
    if typeof(foo) == DataType
        str = string(foo)
    else
        str = string(typeof(foo))
    end
    start = first(findfirst("\"", str))+1
    finish = first(findlast("\"", str))-1
    str = SubString(str, start, finish)
end

function getTypeName(foo)::String
    last(split(getImportName(foo), "."))
end
