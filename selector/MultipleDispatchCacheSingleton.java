package selector;

import java.lang.reflect.Method;
import java.util.HashMap;

public class MultipleDispatchCacheSingleton {

    private static MultipleDispatchCacheSingleton multipleDispatchCacheSingleton;
    private HashMap<String, Method> multipleDispatchCache = new HashMap<>();

    private MultipleDispatchCacheSingleton() {}

    protected static MultipleDispatchCacheSingleton getInstance(){
        if (multipleDispatchCacheSingleton==null)
            multipleDispatchCacheSingleton = new MultipleDispatchCacheSingleton();
        return multipleDispatchCacheSingleton;
    }

    protected boolean isCached(String invocationString){
        return multipleDispatchCache.containsKey(invocationString);
    }

    protected Method getCachedMethod(String invocationString){
        return multipleDispatchCache.get(invocationString);
    }

    protected void putUncachedMethod(String invocationString, Method method){
        if (!isCached(invocationString)) {
            multipleDispatchCache.put(invocationString, method);
        }
    }
}
