package hxdispatch.concurrent;

#if cpp
    import cpp.vm.Lock;
    import cpp.vm.Mutex;
#elseif java
    import java.vm.Lock;
    import java.vm.Mutex;
#elseif neko
    import neko.vm.Lock;
    import neko.vm.Mutex;
#else
    #error "Concurrent Promise is not supported on target platform due to the lack of Lock/Mutex feature."
#end
import hxdispatch.Callback;
import hxdispatch.State;
import hxdispatch.WorkflowException;

/**
 * Thread-safe Promise implementation.
 *
 * This version can be rejected/resolved by other threads and been awaited by them
 * as well (even by multiple threads).
 *
 * @{inherit}
 */
class Promise<T> extends hxdispatch.Promise<T>
{
    /**
     * Stores the Mutex used to synchronize access to properties.
     *
     * @var { state:Mutex, waiters:Mutex }
     */
    private var mutex:{ state:Mutex, waiters:Mutex };

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
     * @{inherit}
     */
    public function new(?resolves:Int = 1):Void
    {
        super(resolves);

        this.mutex   = { state: new Mutex(), waiters: new Mutex() }
        this.lock    = new Lock();
        this.waiters = 0;
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
    override public function done(callback:Callback<T>):Void
    {
        this.mutex.state.acquire();
        var done:Bool = this.state != State.NONE;
        if (!done) {
            this.callbacks.done.add(callback);
            this.mutex.state.release();
        } else {
            this.mutex.state.release();
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function isDone():Bool
    {
        this.mutex.state.acquire();
        var ret:Bool = this.state != State.NONE;
        this.mutex.state.release();

        return ret;
    }

    /**
     * @{inherit}
     */
    override public function isRejected():Bool
    {
        this.mutex.state.acquire();
        var ret:Bool = this.state == State.REJECTED;
        this.mutex.state.release();

        return ret;
    }

    /**
     * @{inherit}
     */
    override public function isResolved():Bool
    {
        this.mutex.state.acquire();
        var ret:Bool = this.state == State.RESOLVED;
        this.mutex.state.release();

        return ret;
    }

    /**
     * Unlocks the Lock that is used to block waiters in await() method.
     *
     * @param Int times the number of times the release() method should be called
     */
    private function unlock(times:Int):Void
    {
        this.mutex.waiters.acquire();
        for (i in 0...times) {
            this.lock.release();
            --this.waiters;
        }
        this.mutex.waiters.release();
    }

    /**
     * @{inherit}
     */
    override public function reject(arg:T):Void
    {
        this.mutex.state.acquire();
        var done:Bool = this.state != State.NONE;
        if (!done) {
            this.state = State.REJECTED;
            this.mutex.state.release();
            this.executeCallbacks(this.callbacks.rejected, arg);
            this.executeCallbacks(this.callbacks.done, arg);
            this.unlock(this.waiters);

            this.callbacks.done     = null;
            this.callbacks.rejected = null;
            this.callbacks.resolved = null;
        } else {
            this.mutex.state.release();
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function rejected(callback:Callback<T>):Void
    {
        this.mutex.state.acquire();
        var done:Bool = this.state != State.NONE;
        if (!done) {
            this.callbacks.rejected.add(callback);
            this.mutex.state.release();
        } else {
            this.mutex.state.release();
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function resolve(arg:T):Void
    {
        this.mutex.state.acquire();
        var done:Bool = this.state != State.NONE;
        if (!done) {
            if (--this.resolves == 0) {
                this.state = State.RESOLVED;
                this.mutex.state.release();
                this.executeCallbacks(this.callbacks.resolved, arg);
                this.executeCallbacks(this.callbacks.done, arg);
                this.unlock(this.waiters);

                this.callbacks.done     = null;
                this.callbacks.rejected = null;
                this.callbacks.resolved = null;
            } else {
                this.mutex.state.release();
            }
        } else {
            this.mutex.state.release();
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function resolved(callback:Callback<T>):Void
    {
        this.mutex.state.acquire();
        var done:Bool = this.state != State.NONE;
        if (!done) {
            this.callbacks.resolved.add(callback);
            this.mutex.state.release();
        } else {
            this.mutex.state.release();
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    public static function when<T>(promises:Array<Promise<T>>):Promise<T>
    {
        var promise:Promise<T> = new Promise<T>(1);
        var done:Bool;
        for (p in promises) {
            p.mutex.state.acquire();
            done = p.state != State.NONE;
            if (!done) {
                ++promise.resolves;
                p.done(function(arg:T):Void {
                    if (p.isRejected()) {
                        promise.reject(arg);
                    } else {
                        promise.resolve(arg);
                    }
                });
            }
            p.mutex.state.release();
        }
        --promise.resolves;

        if (promise.resolves == 0) {
            throw new WorkflowException("Promises have already been rejected or resolved");
        }

        return promise;
    }
}
