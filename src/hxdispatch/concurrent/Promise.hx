package hxdispatch.concurrent;

#if !js
    import hxstd.vm.Mutex;
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
     * @var hxstd.vm.Mutex
     */
    #if !js private var mutex:Mutex; #end


    /**
     * @{inherit}
     */
    public function new(resolves:Int = 1):Void
    {
        super(resolves);
        #if !js this.mutex = new Mutex(); #end
    }

    /**
     * @{inherit}
     */
    override public function done(callback:Callback<T>):Void
    {
        #if !js this.mutex.acquire(); #end
        try {
            super.done(callback);
        } catch (ex:Dynamic) {
            #if !js this.mutex.release(); #end
            throw ex;
        }
        #if !js this.mutex.release(); #end
    }

    /**
     * @{inherit}
     */
    override public function isDone():Bool
    {
        #if !js this.mutex.acquire(); #end
        var ret:Bool = super.isDone();
        #if !js this.mutex.release(); #end

        return ret;
    }

    /**
     * @{inherit}
     */
    override public function isRejected():Bool
    {
        #if !js this.mutex.acquire(); #end
        var ret:Bool = super.isRejected();
        #if !js this.mutex.release(); #end

        return ret;
    }

    /**
     * @{inherit}
     */
    override public function isResolved():Bool
    {
        #if !js this.mutex.acquire(); #end
        var ret:Bool = super.isResolved();
        #if !js this.mutex.release(); #end

        return ret;
    }

    /**
     * @{inherit}
     */
    override public function reject(arg:T):Void
    {
        #if !js this.mutex.acquire(); #end
        if (this.state == State.NONE) {
            this.state = State.REJECTED;
            #if !js this.mutex.release(); #end
            this.executeCallbacks(Lambda.array(this.callbacks.rejected).concat(Lambda.array(this.callbacks.done)), arg); // make sure we iterate over copy

            this.callbacks.done     = null;
            this.callbacks.rejected = null;
            this.callbacks.resolved = null;
        } else {
            #if !js this.mutex.release(); #end
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function rejected(callback:Callback<T>):Void
    {
        #if !js this.mutex.acquire(); #end
        try {
            super.rejected(callback);
        } catch (ex:Dynamic) {
            #if !js this.mutex.release(); #end
            throw ex;
        }
        #if !js this.mutex.release(); #end
    }

    /**
     * @{inherit}
     */
    override public function resolve(arg:T):Void
    {
        #if !js this.mutex.acquire(); #end
        if (this.state == State.NONE) {
            if (--this.resolves == 0) {
                this.state = State.RESOLVED;
                #if !js this.mutex.release(); #end
                this.executeCallbacks(Lambda.array(this.callbacks.resolved).concat(Lambda.array(this.callbacks.done)), arg); // make sure we iterate over copy

                this.callbacks.done     = null;
                this.callbacks.rejected = null;
                this.callbacks.resolved = null;
            } else {
                #if !js this.mutex.release(); #end
            }
        } else {
            #if !js this.mutex.release(); #end
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function resolved(callback:Callback<T>):Void
    {
        #if !js this.mutex.acquire(); #end
        try {
            super.resolved(callback);
        } catch (ex:Dynamic) {
            #if !js this.mutex.release(); #end
            throw ex;
        }
        #if !js this.mutex.release(); #end
    }

    /**
     * @{inherit}
     */
    public static function when<T>(promises:Array<Promise<T>>):Promise<T>
    {
        var promise:Promise<T> = new Promise<T>(1);
        var done:Bool;
        for (p in promises) {
            #if !js p.mutex.acquire(); #end
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
            #if !js p.mutex.release(); #end
        }
        --promise.resolves;

        if (promise.resolves == 0) {
            throw new WorkflowException("Promises have already been rejected or resolved");
        }

        return promise;
    }
}
