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
#elseif !js
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
    #if !js private var mutex:{ state:Mutex, waiters:Mutex }; #end

    /**
     * Stores the Lock used to block await() callers.
     *
     * @var Lock
     */
    #if !js private var lock:Lock; #end

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

        #if !js this.mutex   = { state: new Mutex(), waiters: new Mutex() }
        this.lock    = new Lock(); #end
        this.waiters = 0;
    }

    /**
     * Blocks the calling Thread until the Promise has been marked as done
     * and Callbacks have been processed.
     *
     * JS: This method is not available, but we make the Promise JS compatible so one can
     * use the async version.
     */
    #if !js
        public function await():Void
        {
            if (!this.isDone()) {
                this.mutex.waiters.acquire();
                ++this.waiters;
                this.mutex.waiters.release();

                this.lock.wait();
            }
        }
    #end

    /**
     * @{inherit}
     */
    override public function done(callback:Callback<T>):Void
    {
        #if !js this.mutex.state.acquire(); #end
        var done:Bool = this.state != State.NONE;
        if (!done) {
            this.callbacks.done.add(callback);
            #if !js this.mutex.state.release(); #end
        } else {
            #if !js this.mutex.state.release(); #end
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function isDone():Bool
    {
        #if !js this.mutex.state.acquire(); #end
        var ret:Bool = this.state != State.NONE;
        #if !js this.mutex.state.release(); #end

        return ret;
    }

    /**
     * @{inherit}
     */
    override public function isRejected():Bool
    {
        #if !js this.mutex.state.acquire(); #end
        var ret:Bool = this.state == State.REJECTED;
        #if !js this.mutex.state.release(); #end

        return ret;
    }

    /**
     * @{inherit}
     */
    override public function isResolved():Bool
    {
        #if !js this.mutex.state.acquire(); #end
        var ret:Bool = this.state == State.RESOLVED;
        #if !js this.mutex.state.release(); #end

        return ret;
    }

    /**
     * Unlocks the Lock that is used to block waiters in await() method.
     *
     * @param Int times the number of times the release() method should be called
     *
     * JS: This method is not available, but we make the Promise JS compatible so one can
     * use the async version.
     */
    #if !js
        private function unlock(times:Int):Void
        {
            this.mutex.waiters.acquire();
            for (i in 0...times) {
                this.lock.release();
                --this.waiters;
            }
            this.mutex.waiters.release();
        }
    #end

    /**
     * @{inherit}
     */
    override public function reject(arg:T):Void
    {
        #if !js this.mutex.state.acquire(); #end
        var done:Bool = this.state != State.NONE;
        if (!done) {
            this.state = State.REJECTED;
            #if !js this.mutex.state.release(); #end
            this.executeCallbacks(this.callbacks.rejected, arg);
            this.executeCallbacks(this.callbacks.done, arg);
            #if !js this.unlock(this.waiters); #end

            this.callbacks.done     = null;
            this.callbacks.rejected = null;
            this.callbacks.resolved = null;
        } else {
            #if !js this.mutex.state.release(); #end
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function rejected(callback:Callback<T>):Void
    {
        #if !js this.mutex.state.acquire(); #end
        var done:Bool = this.state != State.NONE;
        if (!done) {
            this.callbacks.rejected.add(callback);
            #if !js this.mutex.state.release(); #end
        } else {
            #if !js this.mutex.state.release(); #end
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function resolve(arg:T):Void
    {
        #if !js this.mutex.state.acquire(); #end
        var done:Bool = this.state != State.NONE;
        if (!done) {
            if (--this.resolves == 0) {
                this.state = State.RESOLVED;
                #if !js this.mutex.state.release(); #end
                this.executeCallbacks(this.callbacks.resolved, arg);
                this.executeCallbacks(this.callbacks.done, arg);
                #if !js this.unlock(this.waiters); #end

                this.callbacks.done     = null;
                this.callbacks.rejected = null;
                this.callbacks.resolved = null;
            } else {
                #if !js this.mutex.state.release(); #end
            }
        } else {
            #if !js this.mutex.state.release(); #end
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function resolved(callback:Callback<T>):Void
    {
        #if !js this.mutex.state.acquire(); #end
        var done:Bool = this.state != State.NONE;
        if (!done) {
            this.callbacks.resolved.add(callback);
            #if !js this.mutex.state.release(); #end
        } else {
            #if !js this.mutex.state.release(); #end
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
            #if !js p.mutex.state.acquire(); #end
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
            #if !js p.mutex.state.release(); #end
        }
        --promise.resolves;

        if (promise.resolves == 0) {
            throw new WorkflowException("Promises have already been rejected or resolved");
        }

        return promise;
    }
}
