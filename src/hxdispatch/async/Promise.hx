package hxdispatch.async;

/**
 *
 */
class Promise<T> extends hxdispatch.concurrent.Promise<T>
{
    /**
     * Stores the Executor used to process Callbacks.
     *
     * @var hxdispatch.async.Executor<hxdispatch.Callback<T>>
     */
    private var executor:Executor<Callback<T>>;


    /**
     * @param hxdispatch.async.Executor<hxdispatch.Callback<T>> the Callback Executor to use
     *
     * @{inherit}
     */
    public function new(executor:Executor<Callback<T>>, ?resolves:Int = 1):Void
    {
        super(resolves);
        this.executor = executor;
    }

    /**
     * @{inherit}
     */
    override private function executeCallbacks(callbacks:Iterable<Callback<T>>, arg:T):Void
    {
        var callback:Callback<T>;
        for (callback in Lambda.array(callbacks)) { // make sure we iterate over a copy
            this.executor.execute(callback, arg);
        }
    }
}
