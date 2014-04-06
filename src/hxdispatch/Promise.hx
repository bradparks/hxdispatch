package hxdispatch;

import hxdispatch.Callback;
import hxdispatch.WorkflowException;
import hxstd.Exception;

/**
 * A Promise can be used to execute registered callbacks as soon as
 * the Promise has been rejected or resolved.
 *
 * This version is not thread safe and therefor not of much use, as it will execute
 * the callbacks in sync (when the last resolve/reject has been called).
 *
 * @generic T the type of the arguments being passed to the callbacks
 */
class Promise<T>
{
    private var callbacks:Array<Callback<T>>;
    private var resolves:Int;

    public var isDone(get, never):Bool;
    public var isRejected(default, null):Bool;
    public var isResolved(default, null):Bool;

    /**
     * Constructor to initialize a new Promise.
     *
     * @param Int resolves the number of required resolves
     */
    public function new(?resolves:Int = 1):Void
    {
        this.callbacks  = new Array<Callback<T>>();
        this.resolves   = resolves;
        this.isRejected = false;
        this.isResolved = false;
    }

    /**
     * Blocks the calling execution thread until the Promise has
     * been marked as rejected or resolved.
     *
     * @throws String always as this method is not implemented in non-threaded version
     */
    public function await():Void
    {
        throw new Exception("await() not supported in non-threaded Promise");
    }

    /**
     * Internal getter method for the isDone property.
     *
     * @return Bool true if the Promise has been rejected or resolved
     */
    private function get_isDone():Bool
    {
        return this.resolves <= 0 && (this.isRejected || this.isResolved);
    }

    /**
     * Executes the registered callbacks with the provided arguments.
     *
     * @param T args the arguments to pass to the callbacks
     */
    private function executeCallbacks(args:T):Void
    {
        var callback:Callback<T>;
        for (callback in this.callbacks) {
            try {
                callback(args);
            } catch (ex:Dynamic) {
                // CallbackException
            }
        }
    }

    /**
     * Rejects the Promise.
     *
     * A rejected Promise is marked as "done" immediately.
     *
     * @throws String if the Promise has already been marked as done
     */
    public function reject():Void
    {
        if (!this.isDone) {
            this.isRejected = true;
        } else {
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * Resolves the Promise with the provided arguments.
     *
     * The arguments are passed to the registered callbacks when this is the last
     * required resolve() call, ignored otherwise.
     *
     * @param T args the arguments to pass to the callbacks
     *
     * @throws String if the Promise has already been marked as done
     */
    public function resolve(args:T):Void
    {
        if (!this.isDone) {
            if (--this.resolves <= 0) {
                this.executeCallbacks(args);
                this.isResolved = true;
            }
        } else {
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * Method allowing to register callbacks to be executed when the Promise
     * has been marked as "done".
     *
     * @param Callback<T> callback the callback to register
     *
     * @throws String if the Promise has already been marked as done
     */
    public function then(callback:Callback<T>):Void
    {
        if (!this.isDone) {
            this.callbacks.push(callback);
        } else {
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * Ad-hook function that allows waiting for multiple Promises at once.
     *
     * @see https://github.com/jdonaldson/promhx where I have stolen the idea
     *
     * @param Array<Promise<T>> promises the Promises to wait for
     *
     * @return Promise<T> a new Promise summarizing the other ones
     *
     * @throws String if all Promises have already been done
     */
    public static function when<T>(promises:Array<Promise<T>>):Promise<T>
    {
        var hasUnresolved:Bool = false;
        var promise:Promise<T> = new Promise<T>(0);
        for (p in promises) {
            if (!p.isDone) {
                hasUnresolved = true;
                ++promise.resolves;
                p.then(function(args:T):Void {
                    promise.resolve(args);
                });
            }
        }

        if (hasUnresolved) {
            throw new WorkflowException("Promises have already been rejected or resolved");
        }

        return promise;
    }
}
