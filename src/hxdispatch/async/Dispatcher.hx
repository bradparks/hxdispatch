package hxdispatch.async;

import hxdispatch.Callback;
import hxdispatch.async.Executor;

/**
 * This Dispatcher implementation is a thread-safe, asynchronous implementation
 * of a Dispatcher.
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
     * @var hxdispatch.async.Executor<hxdispatch.Callback<T>>
     */
    private var executor:Executor<Callback<T>>;


    /**
     * @param hxdispatch.async.Executor<hxdispatch.Callback<T>> the Callback Executor to use
     *
     * @{inherit}
     */
    public function new(executor:Executor<Callback<T>>):Void
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
}
