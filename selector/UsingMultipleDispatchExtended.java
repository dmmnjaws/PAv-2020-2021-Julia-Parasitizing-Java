package selector;

import java.lang.reflect.*;
import java.util.*;
import java.util.stream.Stream;

/**
 * This class is an extension of ist.meic.pava.MultipleDispatch.UsingMultipleDispatch.class and additionally, it implements:
 * - Support for Variable Arity methods.
 * - Support for Memoization of Previous Invocations
 */
public class UsingMultipleDispatchExtended {

    /**
     * This method is called to use Multiple Dispatch (Extended).
     * @param receiver is the receiver object of the method to be invoked
     * @param methodName is the name of the method to be invoked
     * @param varArgs are the parameter objects to be passed to the method to be invoked
     * @return the return of the call to the most suitable method
     */
    public static Object invoke(Object receiver, String methodName, Object... varArgs) {

        Class[] parameterTypes = Stream.of(varArgs)
                .map(object -> object.getClass())
                .toArray(Class[]::new);

        Class receiverType = receiver.getClass();

        // get method cache
        String invocationString = invocationStringBuilder(receiverType, methodName, parameterTypes);
        MultipleDispatchCacheSingleton multipleDispatchCacheSingleton = MultipleDispatchCacheSingleton.getInstance();
        boolean isCached = multipleDispatchCacheSingleton.isCached(invocationString);

        try {
            // if method in cache, return it
            // if method in cache but null, it's known there's no suitable method in the receiver, throw NoSuchMethodException
            // (in absence of method storing null in the cache is redundant in current implementation, it's here for future considerations)
            if(isCached){
                Method method = multipleDispatchCacheSingleton.getCachedMethod(invocationString);
                if (method == null){
                    throw new NoSuchMethodException();
                }

                Object result = (method.isVarArgs()) ? invokeVarArgsMethod(method, receiver, varArgs) : method.invoke(receiver, varArgs);
                return result;
            }

            // if method not in cache, do the usual thing, go check non variable arity methods first
            // if method found, store it in cache
            Method method = bestMethod(receiverType, methodName, parameterTypes);
            multipleDispatchCacheSingleton.putUncachedMethod(invocationString, method);
            return method.invoke(receiver, varArgs);

        } catch (NoSuchMethodException | IllegalAccessException | InvocationTargetException e1) {
            if (e1.getClass().equals(NoSuchMethodException.class)) {
                try {
                    // if NoSuchMethodException() came from null method in cache, rethrow exception, there's no suitable method
                    // (in absence of method storing null in the cache is redundant in current implementation, it's here for future considerations)
                    if(isCached) {
                        throw new NoSuchMethodException();
                    }

                    // if NoSuchMethodException() came from non variable arity search, go look in the variable arity methods
                    // if method found, store it in cache
                    Method method = bestVariableArityMethod(receiverType, methodName, parameterTypes);
                    multipleDispatchCacheSingleton.putUncachedMethod(invocationString, method);
                    return invokeVarArgsMethod(method, receiver, varArgs);

                } catch (NoSuchMethodException | IllegalAccessException | InvocationTargetException e2) {

                    // if no method found, store in cache with null method
                    // (in absence of method storing null in the cache is redundant in current implementation, it's here for future considerations)
                    multipleDispatchCacheSingleton.putUncachedMethod(invocationString, null);
                    throw new RuntimeException(e2);
                }

            }
            throw new RuntimeException(e1);
        }
    }

    /**
     * This method is the entry point to the Multiple Dispatch algorithm that looks for non-variable arity methods.
     * @param receiverType is the type of the receiver of the method to be invoked
     * @param methodName is the name of the method to be invoked
     * @param parameterTypes are the types of the parameters to be passed to the method to be invoked
     * @return the most suitable non-variable arity method to be invoked
     * @throws NoSuchMethodException if no suitable method is found
     */
    public static Method bestMethod(Class receiverType, String methodName, Class[] parameterTypes) throws NoSuchMethodException {

        int orderOfDispatch = parameterTypes.length;
        Method[] acceptableReceiverMethods = getAcceptableReceiverMethods(receiverType, methodName, parameterTypes, orderOfDispatch);

        for (int i = 0; i < orderOfDispatch; i++) {
            acceptableReceiverMethods = filterMethods(acceptableReceiverMethods, parameterTypes[i], i);
        }

        return acceptableReceiverMethods[0];
    }

    /**
     * This method implements part of the Multiple Dispatch algorithm for non-variable arity methods. It has three functions:
     * - Filter an array of non-variable arity methods, keeping only methods whose parameter number parameterIndex is of type parameterType;
     * - If it finds none, recursively call itself with the superclass of the parameter type, climb class hierarchy of the parameter, until it reaches Object.class.
     * - If array of methods is empty at the end of the class hierarchy of a parameter (Object.class), throw NoSuchMethodException
     * @param methods is the array of non-variable arity methods to filter (by now assumed to have only applicable methods)
     * @param parameterType is the desired parameter type
     * @param parameterIndex is the desired parameter index
     * @return filtered array of non-variable arity methods
     * @throws NoSuchMethodException if array of methods is empty and it reached the end of the class hierarchy
     */
    private static Method[] filterMethods(Method[] methods, Class parameterType, int parameterIndex) throws NoSuchMethodException {

        Method[] filteredMethods = Arrays.stream(methods)
                .filter(m -> m.getParameterTypes()[parameterIndex] == parameterType)
                .toArray(Method[]::new);

        try {
            if (filteredMethods.length == 0) {
                throw new NoSuchMethodException();
            } else {
                return filteredMethods;
            }

        } catch (NoSuchMethodException e) {
            if (parameterType == Object.class) {
                throw e;
            } else {
                return filterMethods(methods, parameterType.getSuperclass(), parameterIndex);
            }

        }
    }

    /**
     * This method gets all applicable methods of a receiver's hierarchy, with a given name, and a given number of parameters.
     * @param receiverType is the desired type of the receiver
     * @param methodName is the desired method name
     * @param parameterTypes are the desired parameter types (top of the class hierarchy)
     * @param orderOfDispatch are the number of parameters
     * @return an array of applicable methods.
     */
    private static Method[] getAcceptableReceiverMethods(Class receiverType, String methodName, Class[] parameterTypes, int orderOfDispatch) {

        Method[] acceptableReceiverMethods = Stream.of(receiverType.getMethods())
                .filter(m -> m.getName() == methodName && m.getParameterCount() == orderOfDispatch && !m.isVarArgs())
                .toArray(Method[]::new);

        for (int i = 0; i < orderOfDispatch; i++){
            int finalI = i;
            ArrayList<Class> superClasses = getAllSuperclasses(parameterTypes[i]);
            superClasses.add(parameterTypes[i]);
            acceptableReceiverMethods = Stream.of(acceptableReceiverMethods)
                    .filter(m -> superClasses.contains(m.getParameterTypes()[finalI]))
                    .toArray(Method[]::new);
        }

        return acceptableReceiverMethods;
    }

    /**
     * This method climbs up the class hierarchy of a given parameter type and gets all of it's superclasses.
     * @param parameterType the desired parameter type
     * @return an ArrayList with all superclasses of parameterType.
     */
    private static ArrayList<Class> getAllSuperclasses(Class parameterType){

        ArrayList<Class> allSuperClasses = new ArrayList<>();

        while(parameterType.getSuperclass() != Object.class){
            allSuperClasses.add(parameterType.getSuperclass());
            parameterType = parameterType.getSuperclass();
        }

        allSuperClasses.add(Object.class);

        return allSuperClasses;
    }

    // VARIABLE ARITY

    /**
     * This method is the entry point to the Multiple Dispatch algorithm that looks for variable arity methods.
     * @param receiverType is the type of the receiver of the method to be invoked
     * @param methodName is the name of the method to be invoked
     * @param parameterTypes are the types of the parameters to be passed to the method to be invoked
     * @return the most suitable variable arity method to be invoked
     * @throws NoSuchMethodException if no suitable variable arity method is found
     */
    private static Method bestVariableArityMethod(Class receiverType, String methodName, Class[] parameterTypes) throws NoSuchMethodException {

        int orderOfDispatch = parameterTypes.length;

        Method[] acceptableReceiverMethods = getVarArgsReceiverMethods(receiverType, methodName);
        acceptableReceiverMethods = Arrays.stream(acceptableReceiverMethods)
                .filter(m -> m.getParameterCount() <= orderOfDispatch+1)
                .toArray(Method[]::new);

        Class minimumCommonSuperClass = getMinimumCommonSuperclass(parameterTypes, orderOfDispatch);

        boolean safeMode = false;
        for (int i = 0; i < orderOfDispatch; i++) {
            acceptableReceiverMethods = filterVariableArityMethods(acceptableReceiverMethods, parameterTypes[i], i, safeMode);
            if (!safeMode && i == orderOfDispatch - 1){
                i = 0;
                safeMode = true; }
        }

        if(acceptableReceiverMethods.length == 0){
            throw new NoSuchMethodException();
        }

        Method[] lastCandidateMethods = new Method[]{};

        while(lastCandidateMethods.length == 0){
            Class finalMinimumCommonSuperClass = minimumCommonSuperClass;
            lastCandidateMethods = Arrays.stream(acceptableReceiverMethods)
                .filter(m -> m.getParameterTypes()[m.getParameterCount()-1].getComponentType() == finalMinimumCommonSuperClass)
                .toArray(Method[]::new);
            minimumCommonSuperClass = minimumCommonSuperClass.getSuperclass();
            if (minimumCommonSuperClass == null){ break; }
        }

        Comparator<Method> byParameterCount = Comparator.comparingInt(Method::getParameterCount);
        return Arrays.stream(lastCandidateMethods).max(byParameterCount).get();
    }

    /**
     * This method filters variable arity methods, it's behaviour depends on the safeMode boolean:
     * safeMode == false: filters out all methods whose parameter number parameterIndex isn't in the class hierarchy of parameterType;
     * safeMode == true: (methods assumed to contain only applicable methods) filters out all methods considered less specific.
     * @param methods is the array of variable arity methods to filter (if safeMode == true, assumed to contain only applicable methods)
     * @param parameterType is the desired parameter type
     * @param parameterIndex is the desired parameter index
     * @param safeMode is the boolean that tells the method in which mode to run
     * @return filtered array of methods
     */
    private static Method[] filterVariableArityMethods(Method[] methods, Class parameterType, int parameterIndex, boolean safeMode) {

        ArrayList<Method> filteredMethodsMutable = new ArrayList<>();

        while((!safeMode) || (safeMode && filteredMethodsMutable.isEmpty())){
            Class finalParameterType = parameterType;
            Method[] sameParameterTypeMethods = Arrays.stream(methods)
                    .filter(m -> m.getParameterCount() >= parameterIndex+1 && m.getParameterTypes()[parameterIndex] == finalParameterType)
                    .toArray(Method[]::new);
            Collections.addAll(filteredMethodsMutable, sameParameterTypeMethods);
            parameterType = parameterType.getSuperclass();
            if(parameterType == null){ break; }
        }

        Method[] variableArityMethods = Arrays.stream(methods)
                .filter(m -> m.getParameterCount() <= parameterIndex + 1)
                .toArray(Method[]::new);

        Collections.addAll(filteredMethodsMutable, variableArityMethods);

        return filteredMethodsMutable.toArray(new Method[0]);

    }

    /**
     * This method retrieves the minimum common superclass (MCS) from an array of parameter types.
     * @param parameterTypes is the array of parameter types
     * @param orderOfDispatch is the number of parameters we want to consider for the MCS
     * @return the minimum common superclass
     */
    private static Class getMinimumCommonSuperclass(Class[] parameterTypes, int orderOfDispatch){

        ArrayList<Class> allSuperClasses = new ArrayList<>();

        for (Class parameterType : parameterTypes){
            allSuperClasses.addAll(getAllSuperclasses(parameterType));
        }

        Map<Class, Integer> counter = new HashMap<>();

        for (Class superClass : allSuperClasses) {
            if(!counter.containsKey(superClass)){
                counter.put(superClass, 0);
            }
            counter.put(superClass, counter.get(superClass) + 1);
            if(counter.get(superClass) == orderOfDispatch){
                return superClass;
            }
        }

        return Object.class;
    }

    /**
     * This method gets all var args methods from the receiver hierarchy.
     * @param receiverType is the desired receiver
     * @param methodName is the desired method's name
     * @return an array of methods with all var args methods from the receiver hierarchy
     */
    private static Method[] getVarArgsReceiverMethods(Class receiverType, String methodName) {

        return Stream.of(receiverType.getMethods())
                .filter(m -> m.getName() == methodName && m.isVarArgs())
                .toArray(Method[]::new);
    }

    /**
     * This method prepares the special data structures needed to invoke a variable arity method.
     * @param varArgsMethod the variable arity method to invoke
     * @param receiver the receiver of the variable arity method
     * @param varArgs the arguments to be passed to the variable arity method
     * @return the return of the call to the variable arity method
     * @throws InvocationTargetException
     * @throws IllegalAccessException
     */
    private static Object invokeVarArgsMethod(Method varArgsMethod, Object receiver, Object... varArgs) throws InvocationTargetException, IllegalAccessException {

        int numberOfNonVarParameters = varArgsMethod.getParameterCount() - 1;

        Object[] arguments = Arrays.copyOfRange(varArgs, 0, numberOfNonVarParameters);
        Object[] variableArguments = Arrays.copyOfRange(varArgs, numberOfNonVarParameters, varArgs.length);

        Class<?> varArgsType = varArgsMethod.getParameterTypes()[varArgsMethod.getParameterCount() - 1].getComponentType();

        ArrayList<Object> argumentsArrayList = new ArrayList<>();
        for(int i = 0; i < numberOfNonVarParameters; i++){
            argumentsArrayList.add(arguments[i]);
        }

        argumentsArrayList.add(Array.newInstance(varArgsType, variableArguments.length));

        return varArgsMethod.invoke(receiver, argumentsArrayList.toArray());
    }

    // MEMOIZATION

    /**
     * This method builds the concatenated string that represents an invocation.
     * @param receiverType the type of the receiver of the invocation
     * @param methodName the name of the invoked method
     * @param parameterTypes the type of the parameters of the arguments requested for invocation
     * @return the concatenated string
     */
    private static String invocationStringBuilder(Class receiverType, String methodName, Class[] parameterTypes){
        String invocationString = receiverType.getName() + methodName;

        for (Class parameterType : parameterTypes) {
            invocationString = invocationString + parameterType.getName();
        }

        return invocationString;
    }
}
