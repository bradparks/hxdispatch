package hxdispatch.async;

#if cpp
    import cpp.vm.Lock;
#elseif java
    import java.vm.Lock;
#elseif neko
    import neko.vm.Lock;
#elseif !js
    #error "Async Promise is not supported on target platform due to the lack of Lock feature."
#end

/**
 *
 */
class Promise<T> extends hxdispatch.concurrent.Promise<T>
{
    /**
     * Stores the Executor used to process Callbacks.
     *
     * @var hxdispatch.async.Executor<T>
     */
    private var executor:Executor<T>;

    /**
     * Stores the Lock used to block await() callers.
     *
     * @var Lock
     */
    private var lock:Lock;

    /**
     * Stores the number of waiters.
     *
     * @var Int
     */
    private var waiters:Int;


    /**
     * @param hxdispatch.async.Executor<T> the Callback Executor to use
     *
     * @{inherit}
     */
    public function new(executor:Executor<T>, ?resolves:Int = 1):Void
    {
        super(resolves);
        this.executor = executor;
        this.lock     = new Lock();
        this.waiters  = 0;
    }

    /**
     * Blocks the calling Thread until the Promise has been marked as done
     * and Callbacks have been processed.
     */
    public function await():Void
    {
        if (!this.isDone()) {
            this.mutex.waiters.acquire();
            ++this.waiters;
            this.mutex.waiters.release();

            this.lock.wait();
        }
    }

    /**
     * @{inherit}
     */
    override private function executeCallbacks(callbacks:Array<Callback<T>>, arg:T):Void
    {
        var callback:Callback<T>;
        if (callbacks.length == 0) {
            this.unlock();
        } else {
            for (callback in callbacks) {
                this.executor.execute(function(arg:T):Void {
                    callback(arg);
                    if (callback == callbacks[callbacks.length - 1]) {
                        this.unlock();
                    }
                }, arg);
            }
        }
    }

    /**
     * Unlocks the Lock that is used to block waiters in await() method.
     */
    private function unlock():Void
    {
        this.mutex.waiters.acquire();
        for (i in 0...this.waiters) {
            this.lock.release();
        }
        this.waiters = 0;
        this.mutex.waiters.release();
    }
}
