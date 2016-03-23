import ceylon.collection {
    MutableMap,
    MutableSet
}

import ceylon.language {
    newMap = map
}

shared class ImmutableSetWrapper<Item>(variable Set<Item> immutableSet = emptySet) satisfies MutableSet<Item> 
        given Item satisfies Object {
    
    shared Set<Item> immutable =>
            synchronize { 
                on = this; 
                function do() => immutableSet;
            };
    
    shared actual MutableSet<Item> clone() => ImmutableSetWrapper(immutableSet);
    
    shared actual Iterator<Item> iterator() => immutableSet.iterator();
    
    shared actual Integer hash => immutableSet.hash;
    
    shared actual Boolean equals(Object that) {
        if (is Identifiable that, this === that) {
            return true;
        }
        if (is ImmutableSetWrapper<out Object> that) {
            return immutableSet==that.immutableSet;
        } else if (is Set<Object> that) {
            return immutableSet==that;
        } else {
            return false;
        }
    }
    
    "Clears the whole set,
     and returns the previous contents as un immutable set"
    shared actual Set<Item> clear() => synchronize { 
        on = this; 
        function do() {
            value oldSet = immutableSet;
            immutableSet = emptySet;
            return oldSet;
        }
    };
    
    shared ImmutableSetWrapper<Item> reset({Item*} newItems) => 
            let(do = () {
                if (immutableSet.size != newItems.size
                    || !immutableSet.containsEvery(newItems)) {
                    immutableSet = set(newItems);
                }
                return this;
            }) synchronize(this, do);
    
    shared actual Boolean add(Item element) => 
            let(do = () {
                value alreadyExists = immutableSet.contains(element);
                if (alreadyExists) {
                    return false;
                }
                immutableSet = set (immutableSet.chain {element});
                return true;
            }) synchronize(this, do);
            
    shared actual Boolean addAll({Item*} elements) => 
            let(do = () {
                value containedSomeElements = immutableSet.containsAny(elements);
                immutableSet = set(immutableSet.chain(elements));
                return !containedSomeElements;
            }) synchronize(this, do);
                    
    shared actual Boolean remove(Item element)  => 
            let(do = () {
                value containedTheElement = immutableSet.contains(element);
                if (!containedTheElement) {
                    return false;
                }
                immutableSet = set(
                    immutableSet.filter((elementToKeep) => elementToKeep != element));
                return true;
            }) synchronize(this, do);
    
    shared actual Boolean removeAll({Item*} elements)  => 
            let(do = () {
                value containedAnyElement = immutableSet.containsAny(elements);
                if (containedAnyElement) {
                    immutableSet = set(
                        immutableSet.filter((elementToKeep) => ! elementToKeep in elements));
                }
                return containedAnyElement;
            }) synchronize(this, do);
    
    shared actual String string => immutableSet.string;
}