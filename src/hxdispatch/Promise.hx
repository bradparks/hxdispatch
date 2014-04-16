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
    /**
     * Stores the number of required resolves before the Promise gets marked as done.
     *
     * @var Int
     */
    private var resolves:Int;

    /**
     * Stores the callbacks to be executed for the various state events.
     *
     * @var { done:List<hxdispatch.Callback<T>>, rejected:List<hxdispatch.Callback<T>>, resolved:List<hxdispatch.Callback<T>> }
     */
    private var callbacks:{ done:List<Callback<T>>, rejected:List<Callback<T>>, resolved:List<Callback<T>> };

    /**
     * Stores the status.
     *
     * @var hxdispatch.Promise.Status
     */
    private var status:Status;


    /**
     * Constructor to initialize a new Promise.
     *
     * @param Int resolves the number of required resolves before the Promise gets marked as done
     */
    public function new(?resolves:Int = 1):Void
    {
        this.callbacks = { done: new List<Callback<T>>(), rejected: new List<Callback<T>>(), resolved: new List<Callback<T>>() };
        this.resolves  = resolves;
        this.status    = Status.NONE;
    }

    /**
     * Method allowing to register callbacks to be executed when the Promise
     * has been marked as done.
     *
     * @param hxdispatch.Callback<T> callback the callback to register
     *
     * @throws hxdispatch.WorkflowException if the Promise has already been marked as done
     */
    public function done(callback:Callback<T>):Void
    {
        if (!this.isDone()) {
            this.callbacks.done.add(callback);
        } else {
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * Checks if the Promise has been marked as done.
     *
     * @return Bool
     */
    public function isDone():Bool
    {
        return this.status != Status.NONE;
    }

    /**
     * Checks if the Promise has been rejected.
     *
     * @return Bool
     */
    public function isRejected():Bool
    {
        return this.status == Status.REJECTED;
    }

    /**
     * Checks if the Promise has been resolved.
     *
     * @return Bool
     */
    public function isResolved():Bool
    {
        return this.status == Status.RESOLVED;
    }

    /**
     * Executes the registered callbacks with the provided argument.
     *
     * @param Iterable<hxdispatch.Callback<T>> callbacks the callbacks to execute
     * @param T                                arg       the argument to pass to the callbacks
     */
    private function executeCallbacks(callbacks:Iterable<Callback<T>>, arg:T):Void
    {
        var callback:Callback<T>;
        for (callback in callbacks) {
            try {
                callback(arg);
            } catch (ex:Dynamic) {
                // CallbackException
            }
        }
    }

    /**
     * Rejects the Promise.
     *
     * A rejected Promise is marked as done immediately.
     *
     * @throws hxdispatch.WorkflowException if the Promise has already been marked as done
     */
    public function reject(?arg:T = null):Void
    {
        if (!this.isDone()) {
            this.status = Status.REJECTED;
            this.executeCallbacks(this.callbacks.rejected, arg);
            this.executeCallbacks(this.callbacks.done, arg);

            this.callbacks.done     = null;
            this.callbacks.rejected = null;
            this.callbacks.resolved = null;
        } else {
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * Method allowing to register callbacks to be executed when the Promise
     * has rejected.
     *
     * @param hxdispatch.Callback<T> callback the callback to register
     *
     * @throws hxdispatch.WorkflowException if the Promise has already been marked as done
     */
    public function rejected(callback:Callback<T>):Void
    {
        if (!this.isDone()) {
            this.callbacks.rejected.add(callback);
        } else {
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * Resolves the Promise with the provided argument.
     *
     * The argument is passed to the registered callbacks when this is the last
     * required resolve() call, ignored otherwise.
     *
     * @param T arg the argument to pass to the callbacks
     *
     * @throws hxdispatch.WorkflowException if the Promise has already been marked as done
     */
    public function resolve(?arg:T = null):Void
    {
        if (!this.isDone()) {
            if (--this.resolves == 0) {
                this.status = Status.RESOLVED;
                this.executeCallbacks(this.callbacks.resolved, arg);
                this.executeCallbacks(this.callbacks.done, arg);

                this.callbacks.done     = null;
                this.callbacks.rejected = null;
                this.callbacks.resolved = null;
            }
        } else {
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * Method allowing to register callbacks to be executed when the Promise
     * has resolved.
     *
     * @param hxdispatch.Callback<T> callback the callback to register
     *
     * @throws hxdispatch.WorkflowException if the Promise has already been marked as done
     */
    public function resolved(callback:Callback<T>):Void
    {
        if (!this.isDone()) {
            this.callbacks.resolved.add(callback);
        } else {
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * Returns a new Promise that will get marked as done when all passed
     * Promises have been marked as done.
     *
     * @see https://github.com/jdonaldson/promhx where I have stolen the idea
     *
     * @param Iterable<hxdispatch.Promise<T>> promises the Promises to wait for
     *
     * @return hxdispatch.Promise<T> a new Promise summarizing the other ones
     *
     * @throws hxdispatch.WorkflowException if all Promises have already been marked as done
     */
    public static function when<T>(promises:Iterable<Promise<T>>):Promise<T>
    {
        var promise:Promise<T> = new Promise<T>(1);
        for (p in promises) {
            if (!p.isDone()) {
                ++promise.resolves;
                p.done(function(arg:T):Void {
                    if (p.isRejected()) {
                        promise.reject(arg);
                    } else {
                        promise.resolve(arg);
                    }
                });
            }
        }
        --promise.resolves;

        if (promise.resolves == 0) {
            throw new WorkflowException("Promises have already been rejected or resolved");
        }

        return promise;
    }
}


/**
 * Statuses representing the various states a Promise can have.
 */
private enum Status
{
    NONE;     // newly initialized
    REJECTED;
    RESOLVED;
}
