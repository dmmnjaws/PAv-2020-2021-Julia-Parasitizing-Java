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
j_u_arrays = @jimport java.util.Arrays
jcall(j_u_arrays, "binarySearch", jint, (Array{jint,1}, jint), [10,20,30,40,50,60], 40)
jcall(j_u_arrays, "binarySearch", jint, (Array{JObject,1}, JObject), ["123","abc","uvw","xyz"], "uvw")

paramTypeTuple = (JObject, JString, Array{JObject, 1})
javaDispatcher = JavaCall.jimport("selector.UsingMultipleDispatchExtended")
invokeMethod = first(listmethods(javaDispatcher))
jcall(javaDispatcher, "invoke", JObject, paramTypeTuple, printer, "draw", paramValueTuple)

# JavaCall 0.7.8 bug - wrongful primitive Java types convertion:
method = first(listmethods(printer, "compute"))
methodreturntype = JavaCall.jimport(getname(getreturntype(method)))
methodparametertypes = tuple(map(x-> JavaCall.jimport(getname(x)), getparametertypes(method))...)
methodname = jcall(method, "getName", JString, (),)
# this fails because returntype and parametertypes are JavaObject{:int}, which are aparently not the same as jint = Int32:
jcall(printer, methodname, methodreturntype, methodparametertypes, 1, 1)
# this works:
jcall(printer, methodname, jint, (jint, jint), 1, 1)


# TESTS TO Java-Parazite-Julia:

# INIT
using JavaCall
JavaCall.init(["-Xmx512M", "-Djava.class.path=$(@__DIR__)"])
Printer = JavaCall.jimport("statement.Printer")
printer = Printer(())
Screen = JavaCall.jimport("statement.Screen")
screen = Screen(())
Line = JavaCall.jimport("statement.Line")
line = Line(())
line2 = Line(())
Brush = JavaCall.jimport("statement.Brush")
brush = Brush(())
J_u_arrays = @jimport java.util.Arrays
j_u_arrays = J_u_arrays()

# WORKING
@jcall printer.compute(1, 1)
@jcall printer.compute(Int32(1), Int32(1))
@jcall printer.staticMethod("ola")
@jcall Printer.staticMethod("ola")
@jcall screen.staticMethod("ola")
@jcall Screen.staticMethod("ola")
@jcall printer.staticMethod(["ola", " ", "adeus"])
@jcall Printer.staticMethod(["ola", " ", "adeus"])
@jcall printer.draw(line, brush)
@jcall screen.draw(line, brush)
@jcall printer.staticMethod([line])
@jcall printer.staticMethod([line, line2])
@jcall J_u_arrays.binarySearch([1,2,3,4], 2)
@jcall j_u_arrays.binarySearch([1,2,3,4], 2)

# NOT WORKING
@jcall J_u_arrays.binarySearch(["1","2","3","4"], "2")
@jcall j_u_arrays.binarySearch(["1","2","3","4"], "2")
