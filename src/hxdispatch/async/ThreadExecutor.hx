package hxdispatch.async;

#if js
    import cpp.vm.Thread;
#elseif !(cpp || java || neko)
    #error "Threaded Executor is not supported on target platform due to the lack of Thread feature."
#end
import hxdispatch.Callback;
import hxdispatch.async.Executor;
import hxstd.vm.Thread;

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
