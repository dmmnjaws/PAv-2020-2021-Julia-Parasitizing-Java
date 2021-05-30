# TESTS TO Java-Parazite Julia:

# In order to run the tests:
# 0. Evaluate either Java-Parazite-Julia-LoadOnStartUp or Java-Parazite-Julia-LoadOnDemand
# 1. Run, in the REPL, the three lines listed in the INIT section.
# 2. Run lines listed in the LOSU-INIT section, if testing LoadOnStartup, or LOD-INIT, if testing LoadOnDemand
# 2-alt. OR, for BENCHMARKING, evaluate and run either @time initOnStartUpV() or @time initOnDemandV(), in the BENCHMARKING section.
# 3. Run the lines listed in WORKING - REGRESSION TEST SUITE, and inspect the results. Used Java Classes are all present in the statement folder.
# 3-alt. OR, for BENCHMARKING, evaluate and run @time regressionTestSuite, in the BENCHMARKING section

# INIT
using JavaCall
using BenchmarkTools
JavaCall.init(["-Xmx512M", "-Djava.class.path=$(@__DIR__)"])

# LOD-INIT (exclusive to LoadOnDemand, won't work with LoadOnStartUp)
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

# LOSU-INIT (exclusive to LoadOnStartUp, to test @jimport syntax)
Printer = @jimport "statement.Printer"
printer = Printer(())
printer2 = Printer(())
Screen = @jimport "statement.Screen"
screen = Screen(())
Line = @jimport "statement.Line"
line = Line(())
line2 = Line(())
Brush = @jimport "statement.Brush"
brush = Brush(())
J_u_arrays = @jimport "java.util.Arrays"
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
# BENCHMARKING
# skipping the @jcall and @jimport macros, but effectively doing the same thing...

function initOnDemandV()
    global Printer = JavaCall.jimport("statement.Printer")
    global printer = Printer(())
    global printer2 = Printer(())
    global Screen = JavaCall.jimport("statement.Screen")
    global screen = Screen(())
    global Line = JavaCall.jimport("statement.Line")
    global line = Line(())
    global line2 = Line(())
    global Brush = JavaCall.jimport("statement.Brush")
    global brush = Brush(())
    global J_u_arrays = @jimport java.util.Arrays
    global j_u_arrays = J_u_arrays()
    "init concluded"
end

function initOnStartUpV()
    global Printer = jimport("statement.Printer")
    global printer = Printer(())
    global printer2 = Printer(())
    global Screen = jimport("statement.Screen")
    global screen = Screen(())
    global Line = jimport("statement.Line")
    global line = Line(())
    global line2 = Line(())
    global Brush = jimport("statement.Brush")
    global brush = Brush(())
    global J_u_arrays = jimport("java.util.Arrays")
    global j_u_arrays = J_u_arrays()
    "init concluded"
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
    j(:(printer2.incrementGlobalVar(Int32(2))))
    "tests concluded"
end

# BENCHMARK LoadOnDemand
@time initOnDemandV()
@time regressionTestSuite()
@time regressionTestSuite()

# BENCHMARK LoadOnStartUp
@time initOnStartupV()
@time regressionTestSuite()
@time regressionTestSuite()
