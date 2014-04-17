package hxdispatch.concurrent;

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
import hxdispatch.Event.Args;

/**
 * The ThreadDispatcher implementation is a thread-safe, asynchronous implementation
 * of a Dispatcher.
 *
 * Each Callback is executed within its own thread and therefor fully non-blocking.
 *
 * It's recommended to use this implementation for long-running callbacks that are not triggered
 * to often (as this would spawn a lot threads).
 *
 * @{inherit}
 */
class ThreadDispatcher<A:Args> extends hxdispatch.concurrent.Dispatcher<A>
{
    /**
     * @{inherit}
     */
    override private function executeCallback(callback:Callback<A>, arg:Null<A>):Void
    {
        #if !js
            Thread.create(function():Void {
                try {
                    callback(arg);
                } catch (ex:Dynamic) {
                    // CallbackException
                }
            });
        #else
            Timer.delay(function():Void {
                try {
                    callback(arg);
                } catch (ex:Dynamic) {
                    // CallbackException
                }
            }, 0);
        #end
    }
}
