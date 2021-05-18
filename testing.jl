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
    elseif primitive == JString || primitive == String
        JString
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
    elseif primitive == JavaObject{Symbol("java.lang.String[]")} || primitive == Array{JavaObject{Symbol("java.lang.String")},1}
        exprArrayTypeBuilder(:JString)
    elseif primitive == Nothing
        Nothing
    else
        expr = importExprBuilder(getImportName(primitive))
        eval(expr)
        expr.args[1]
    end
end

function convertArgument(argument)
    if typeof(argument) == String
        convert(JString, argument)
    elseif typeof(eval(argument)) == Array{String,1}
        convert(Array{JString, 1}, eval(argument))
    else
        argument
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
        arg = convertArgument(arg)
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
        parameterTypes = getparametertypes(method)
        parameterTypes = tuple(map(x -> eval(convertPrimitive(JavaCall.jimport(getname(x)))), parameterTypes)...)
        returnType = convertPrimitive(JavaCall.jimport(getname(getreturntype(method))))
        methodName = jcall(method, "getName", JString, (),)
        exprImplementation = exprImplementationBuilder(receiver, methodName, returnType, parameterTypes)

        if jcall(method, "getModifiers", jint, (), ) == 9
            exprSignature = exprSignatureBuilder(receiver, methodName, parameterTypes, true)
            expression = exprBuilder(exprSignature, exprImplementation)
            eval(expression)
        else
            exprSignature = exprSignatureBuilder(receiver, methodName, parameterTypes, false)
            expression = exprBuilder(exprSignature, exprImplementation)
            eval(expression)
        end
    end
end

function exprSignatureBuilder(receiver, methodName::String, parameterTypes, isStatic::Bool)
    expr = :()
    expr.head = :call
    push!(expr.args, Symbol(methodName))
    i = "a"
    if isStatic
        staticTypeExpr = exprStaticReceiverBuilder(getImportName(receiver))
        push!(expr.args, exprParameterBuilder(Symbol("receiver"), staticTypeExpr))
    else
        push!(expr.args, exprParameterBuilder(Symbol("receiver"), Symbol(convertPrimitive(receiver))))
    end
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

function exprStaticReceiverBuilder(importName::String)
    expr = :()
    expr.head = :curly
    push!(expr.args, :Type)
    inexpr = :()
    inexpr.head = :curly
    push!(inexpr.args, :JavaObject)
    ininexpr = :()
    ininexpr.head = :call
    push!(ininexpr.args, :Symbol)
    push!(ininexpr.args, importName)
    push!(inexpr.args, ininexpr)
    push!(expr.args, inexpr)
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
