package hxdispatch.async;

import hxdispatch.Callback;

/**
 * The Executor typedef can be used to realize an asynchronous
 * function/callback handler that processed the argument passed
 * to the execute() function without blocking the caller.
 *
 * @generic T the type of argument(s) the Callbacks accept
 */
typedef Executor<T> =
{
    /**
     * Executes the provided Callback with the given argument.
     *
     * @param hxdispatch.Callback<T> callback the Callback to execute
     * @param T                      arg      the argument to pass to the Callback
     */
    public function execute(callback:Callback<T>, arg:T):Void;
}


/**
 * Sequential Executor to be used as a fallback for situations
 * where an Executor is required but we do not want an async one.
 */
class Sequential<T> // implements Executor<T>
{
    /**
     * @{inherit}
     */
    public function execute(callback:Callback<T>, arg:T):Void
    {
        callback(arg);
    }
}
