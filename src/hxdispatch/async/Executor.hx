package hxdispatch.async;

import hxdispatch.Callback;

/**
 * The Executor interface can be used to realize an asynchronous
 * function/callback handler that processed the argument passed
 * to the execute() function without blocking the caller.
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
