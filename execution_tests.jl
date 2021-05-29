# TESTS TO Java-Parazite Julia:

# INIT
using JavaCall
using BenchmarkTools
JavaCall.init(["-Xmx512M", "-Djava.class.path=$(@__DIR__)"])
Printer = JavaCall.jimport("statement.Printer")
printer = Printer(())
printer2 = Printer(())
Screen = JavaCall.jimport("statement.Screen")
screen = Screen(())
Line = JavaCall.jimport("statement.Line")
line = Line(())
line2 = Line(())
Brush = JavaCall.jimport("statement.Brush")
brush = Brush(())
J_u_arrays = @jimport java.util.Arrays
j_u_arrays = J_u_arrays()

# WORKING - REGRESSION TEST SUITE
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
@jcall printer.returnInt(Int32(1))
@jcall printer.returnLong(Int64(1))
@jcall printer.returnFloat(Float32(1))
@jcall printer.returnDouble(Float64(1))
@jcall printer.returnChar(UInt16(1))
@jcall printer.returnChar(Char(1))
@jcall printer.returnBoolean(UInt8(0))
@jcall printer.returnBoolean(true)
@jcall printer.returnShort(Int16(1))
@jcall printer.returnByte(Int8(1))
@jcall printer.returnString("ola")
@jcall printer.returnIntArray([Int32(1), Int32(2)])
@jcall printer.returnLongArray([Int64(1), Int64(2)])
@jcall printer.returnFloatArray([Float32(1), Float32(2)])
@jcall printer.returnDoubleArray([Float64(1), Float64(2)])
@jcall printer.returnCharArray([UInt16(1), UInt16(2)])
@jcall printer.returnCharArray([Char(1), Char(2)])
@jcall printer.returnBooleanArray([UInt8(0), UInt8(1)])
@jcall printer.returnBooleanArray([true, false])
@jcall printer.returnShortArray([Int16(1), Int16(2)])
@jcall printer.returnByteArray([Int8(1), Int8(2)])
@jcall printer.returnStringArray(["ola", "adeus"])
@jcall printer.incrementGlobalVar(Int32(2))
@jcall printer.incrementGlobalVar(Int32(220))
@jcall printer2.incrementGlobalVar(Int32(2))

# NOT WORKING
@jcall J_u_arrays.binarySearch(["1","2","3","4"], "2")
@jcall j_u_arrays.binarySearch(["1","2","3","4"], "2")








# -------------------------------------------------------------------
# BENCHMARKS
# skipping the @jcall macro, but effectively doing the same thing...

function initOnStartupV()
    global Printer = jimport("statement.Printer")
    global printer = Printer(())
    global Screen = jimport("statement.Screen")
    global screen = Screen(())
    global Line = jimport("statement.Line")
    global line = Line(())
    global line2 = Line(())
    global Brush = jimport("statement.Brush")
    global brush = Brush(())
    global J_u_arrays = jimport("java.util.Arrays")
    global j_u_arrays = J_u_arrays()
end

function initOnDemandV()
    global Printer = JavaCall.jimport("statement.Printer")
    global printer = Printer(())
    global Screen = JavaCall.jimport("statement.Screen")
    global screen = Screen(())
    global Line = JavaCall.jimport("statement.Line")
    global line = Line(())
    global line2 = Line(())
    global Brush = JavaCall.jimport("statement.Brush")
    global brush = Brush(())
    global J_u_arrays = @jimport java.util.Arrays
    global j_u_arrays = J_u_arrays()
end

function regressionTestSuite()
    j(:(printer.compute(1, 1)))
    j(:(printer.compute(Int32(1), Int32(1))))
    j(:(printer.staticMethod("ola")))
    j(:(Printer.staticMethod("ola")))
    j(:(screen.staticMethod("ola")))
    j(:(Screen.staticMethod("ola")))
    j(:(printer.staticMethod(["ola", " ", "adeus"])))
    j(:(Printer.staticMethod(["ola", " ", "adeus"])))
    j(:(printer.draw(line, brush)))
    j(:(screen.draw(line, brush)))
    j(:(printer.staticMethod([line])))
    j(:(printer.staticMethod([line, line2])))
    j(:(J_u_arrays.binarySearch([1,2,3,4], 2)))
    j(:(j_u_arrays.binarySearch([1,2,3,4], 2)))
    j(:(printer.returnInt(Int32(1))))
    j(:(printer.returnLong(Int64(1))))
    j(:(printer.returnFloat(Float32(1))))
    j(:(printer.returnDouble(Float64(1))))
    j(:(printer.returnChar(UInt16(1))))
    j(:(printer.returnChar(Char(1))))
    j(:(printer.returnBoolean(UInt8(0))))
    j(:(printer.returnBoolean(true)))
    j(:(printer.returnShort(Int16(1))))
    j(:(printer.returnByte(Int8(1))))
    j(:(printer.returnString("ola")))
    j(:(printer.returnIntArray([Int32(1), Int32(2)])))
    j(:(printer.returnLongArray([Int64(1), Int64(2)])))
    j(:(printer.returnFloatArray([Float32(1), Float32(2)])))
    j(:(printer.returnDoubleArray([Float64(1), Float64(2)])))
    j(:(printer.returnCharArray([UInt16(1), UInt16(2)])))
    j(:(printer.returnCharArray([Char(1), Char(2)])))
    j(:(printer.returnBooleanArray([UInt8(0), UInt8(1)])))
    j(:(printer.returnBooleanArray([true, false])))
    j(:(printer.returnShortArray([Int16(1), Int16(2)])))
    j(:(printer.returnByteArray([Int8(1), Int8(2)])))
    j(:(printer.returnStringArray(["ola", "adeus"])))
    j(:(printer.incrementGlobalVar(Int32(2))))
    j(:(printer.incrementGlobalVar(Int32(220))))
    "benchmark concluded"
end

# On-Demand Version
@time initOnDemandV()
@time regressionTestSuite()
@time regressionTestSuite()

# On-Startup Version
@time initOnStartupV()
@time regressionTestSuite()
@time regressionTestSuite()
