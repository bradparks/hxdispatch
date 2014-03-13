package hxdispatch.threaded;

#if cpp
    import cpp.vm.Thread;
#elseif java
    import java.vm.Thread;
#elseif js
    import haxe.Timer;
#elseif neko
    import neko.vm.Thread;
#else
    #error "ThreadDispatcher is not supported on target platform due to the lack of Thread feature."
#end
import hxdispatch.Callback;

/**
 *
 */
class ThreadDispatcher<T> extends hxdispatch.threaded.Dispatcher<T>
{
    /**
     * @{inherit}
     */
    override private function executeCallback(callback:Callback<T>, args:Null<T>):Void
    {
        #if !js
        Thread.create(function():Void {
            callback(args);
        });
        #else
        Timer.delay(function():Void {
            callback(args);
        }, 0);
        #end
    }
}
