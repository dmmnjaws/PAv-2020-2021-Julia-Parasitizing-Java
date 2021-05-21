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
}
