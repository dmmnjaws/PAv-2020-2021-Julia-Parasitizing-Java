package utils;

import java.util.ArrayList;

public class Helper{

    /**
     * This method climbs up the class hierarchy of a given parameter type and gets all of it's superclasses.
     * @param parameterType the desired parameter type
     * @return an ArrayList with all superclasses of parameterType.
     */
    public static Class[] getAllSuperclasses(Class parameterType){

        ArrayList<Class> allSuperClasses = new ArrayList<>();
        allSuperClasses.add(parameterType);

        while(parameterType.getSuperclass() != Object.class){
            allSuperClasses.add(parameterType.getSuperclass());
            parameterType = parameterType.getSuperclass();
        }

        allSuperClasses.add(Object.class);
        return allSuperClasses.toArray(new Class[0]);
    }
}
