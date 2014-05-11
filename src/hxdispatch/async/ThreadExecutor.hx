package hxdispatch.async;

#if (cpp || cs || java || neko)
    import hxstd.vm.Thread;
#elseif js
    import haxe.Timer;
#elseif
    #error "Threaded Executor is not supported on target platform due to the lack of Thread feature."
#end
import hxdispatch.Callback;
import hxdispatch.async.Executor;

/**
 * The ThreadExecutor is an Executor implementation that processes
 * each callback within its own thread.
 *
 * It is well-suited for long running operations, but less for frequent executions.
 */
class ThreadExecutor<T> implements Executor<T>
{
    /**
     * Constructor to initialize a new ThreadExecutor.
     */
    public function new():Void {}

    /**
     * @{inherit}
     */
    public function execute(callback:Callback<T>, arg:T):Void
    {
        #if !js
            Thread.create(function():Void {
                callback(arg);
            });
        #else
            Timer.delay(function():Void {
                callback(arg);
            }, 0);
        #end
    }
}
