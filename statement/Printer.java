package statement;

public class Printer extends Device {
    public void draw(Line l, Brush b) {
        System.err.println("drawing a line on printer with what?");
    }
    public void draw(Circle c, Pencil p) {
        System.err.println("drawing a circle on printer with pencil!");
    }
    public void draw(Circle c, Crayon r) {
        System.err.println("drawing a circle on printer with crayon!");
    }

    public int compute(int i, int j) {
        return i+j;
    }

    public int compute(float i, float j) {
        return (int)i+(int)j+1000;
    }

    public int compute(long i, long j) {
        return (int)i+(int)j+2000;
    }

    public int compute(long[] v){
        int res = 0;
        for (long l : v){ res = res+(int)l; }
        return (int)res;
    }

    public static String staticMethod(String string){
        return string;
    }

    public static String staticMethod(String[] v){
        String res = "";
        for (String l : v){ res = res+l; }
        return res;
    }

    public static int staticMethod(Line[] v){
        if (v.length == 1) {
            return 1;
        } else if (v.length == 2) {
            return 2;
        } else {
            return 3;
        }
    }

    public int returnInt(int i){
        return i;
    }

    public long returnLong(long l){
        return l;
    }

    public float returnFloat(float f){
        return f;
    }

    public double returnDouble(double d){
        return d;
    }

    public char returnChar(char c){
        return c;
    }

    public boolean returnBoolean(boolean b){
        return b;
    }

    public short returnShort(short s){
        return s;
    }

    public byte returnByte(byte b){
        return b;
    }

    public String returnString(String s){
        return s;
    }

    public int[] returnIntArray(int[] i){
        return i;
    }

    public long[] returnLongArray(long[] l){
        return l;
    }

    public float[] returnFloatArray(float[] f){
        return f;
    }

    public double[] returnDoubleArray(double[] d){
        return d;
    }

    public char[] returnCharArray(char[] c){
        return c;
    }

    public boolean[] returnBooleanArray(boolean[] b){
        return b;
    }

    public short[] returnShortArray(short[] s){
        return s;
    }

    public byte[] returnByteArray(byte[] b){
        return b;
    }

    public String[] returnStringArray(String[] s){
        return s;
    }

}
