package hxdispatch.async;

#if (cpp || cs || flash || java || neko)
    import hxstd.vm.Mutex;
#elseif !js
    #error "Async Dispatcher is not supported on target platform due to the lack of Mutex feature."
#end
#if (flash || js)
    import hxdispatch.concurrent.Promise;
#else
    import hxdispatch.async.Promise;
#end
import hxdispatch.Callback;
import hxdispatch.Dispatcher.Status;
import hxstd.threading.Executor;
import hxstd.Nil;

/**
 * This Dispatcher implementation is a thread-safe, asynchronous implementation.
 *
 * Each Callback is executed by the asynchronous Executor.
 *
 * TODO: bug on line 69 (upstream?)
 *
 * @{inherit}
 */
class Dispatcher<T> extends hxdispatch.concurrent.Dispatcher<T>
{
    /**
     * Stores the Executor used to process Callbacks.
     *
     * @var hxstd.threading.Executor<T>
     */
    private var executor:Executor<T>;


    /**
     * @param hxstd.threading.Executor<T> the Callback Executor to use
     *
     * @{inherit}
     */
    public function new(executor:Executor<T>):Void
    {
        super();
        this.executor = executor;
    }

    /**
     * @{inherit}
     */
    override private function executeCallback(callback:Callback<T>, arg:T):Void
    {
        this.executor.execute(callback, arg);
    }

    /**
     * @{inherit}
     */
    override public function trigger(event:Event, arg:T):Feedback
    {
        if (this.hasEvent(event)) {
            #if !js this.mutex.acquire(); #end
            var callbacks:Array<Callback<T>> = this.map.get(event).copy();
            #if !js
                var promise:Promise<Nil> = new Promise<Nil>(new hxstd.threading.Executor.Sequential<Nil>(), callbacks.length);
            #else
                var promise:Promise<Nil> = new Promise<Nil>(callbacks.length);
            #end
            #if !js this.mutex.release(); #end
            var callback:Callback<T>;
            for (callback in callbacks) {
                this.executeCallback(function(arg:T):Void {
                    callback(arg);
                    promise.resolve(null);
                }, arg);
            }

            return { status: Status.TRIGGERED, promise: promise };
        }

        return { status: Status.NO_SUCH_EVENT };
    }
}


/**
 * @{inherit}
 */
typedef Feedback =
{> hxdispatch.Dispatcher.Feedback,
    @:optional public var promise:Promise<Nil>;
};
