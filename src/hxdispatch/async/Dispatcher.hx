package hxdispatch.async;

#if !js
    import hxstd.vm.Mutex;
#end
#if flash
    import hxdispatch.concurrent.Promise;
#else
    import hxdispatch.async.Promise;
#end
import hxdispatch.Callback;
import hxdispatch.Dispatcher.Status;
import hxstd.threading.ExecutionContext;
import hxstd.threading.IExecutor;
import hxstd.Nil;

/**
 * This Dispatcher implementation is a thread-safe, asynchronous implementation.
 *
 * Each Callback is executed by the asynchronous Executor.
 *
 * @{inherit}
 */
class Dispatcher<T> extends hxdispatch.concurrent.Dispatcher<T>
{
    /**
     * Stores the Executor used to process Callbacks.
     *
     * @var hxstd.threading.IExecutor
     */
    private var executor:IExecutor;


    /**
     * Constructor to initialize a new asynchronous Dispatcher.
     *
     * @param hxstd.threading.IExecutor the Callback Executor to use
     */
    public function new(executor:IExecutor):Void
    {
        super();
        this.executor = executor;
    }

    /**
     * @{inherit}
     */
    override public function trigger(event:Event, arg:T):Feedback
    {
        #if !js this.mutex.acquire(); #end
        if (this.hasEvent(event)) {
            var callbacks = Lambda.array(this.map.get(event)); // make sure the list doesnt change anymore
            #if !js this.mutex.release(); #end
            var promise:Promise<Nil> = new Promise<Nil>(ExecutionContext.preferedExecutor, callbacks.length);

            var callback:Callback<T>;
            for (callback in callbacks) {
                this.executor.execute(function(arg:T):Void {
                    #if HXDISPATCH_DEBUG
                        try {
                            callback(arg);
                        } catch (ex:Dynamic) {
                            promise.resolve(null);
                            throw ex;
                        }
                    #else
                        try {
                            callback(arg);
                        } catch (ex:Dynamic) {}
                    #end
                    promise.resolve(null);
                }, arg);
            }

            return { status: Status.TRIGGERED, promise: promise };
        } else {
            #if !js this.mutex.release(); #end
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
