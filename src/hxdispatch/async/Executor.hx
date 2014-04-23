package hxdispatch.async;

import hxdispatch.Callback;

/**
 * The Executor interface can be used to realize an asynchronous
 * function/callback handler that processed the argument passed
 * to the execute() function without blocking the caller.
 *
 * @see https://github.com/andyli/hxAnonCls for a nice way to init anonymous Executors
 *
 * @generic T the type of argument(s) the Callbacks accept
 */
interface Executor<T>
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
class Sequential<T> implements Executor<T>
{
    /**
     * Constructor to initialize a new Sequential.
     */
    public function new():Void {}

    /**
     * @{inherit}
     */
    public function execute(callback:Callback<T>, arg:T):Void
    {
        callback(arg);
    }
}
