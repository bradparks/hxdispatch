package hxdispatch.utils;

#if cpp
    import cpp.vm.Deque;
#elseif java
    import java.vm.Deque;
#elseif neko
    import neko.vm.Deque;
#else
    #error "DequeTools is not supported on target platform due to the lack of Deque feature."
#end

/**
 *
 */
class DequeTools
{
    @:generic
    public static function iterator<T>(deque:Deque<T>):Iterator<T>
    {
        return null;
    }
}
