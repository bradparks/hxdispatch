package hxdispatch.threaded;

#if cpp
    import cpp.vm.Deque;
    import cpp.vm.Mutex;
    import cpp.vm.Thread;
#elseif java
    import java.vm.Deque;
    import java.vm.Mutex;
    import java.vm.Thread;
#elseif neko
    import neko.vm.Deque;
    import neko.vm.Mutex;
    import neko.vm.Thread;
#else
    #error "Threaded Promise is not supported on target platform due to the lack of Deque/Mutex/Thread feature."
#end
import hxdispatch.Callback;
import hxdispatch.WorkflowException;
import hxdispatch.threaded.Signal;

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
    private var thens:Deque<Callback<T>>;
    private var waiters:Deque<Thread>;
    private var mutex:Mutex;

    /**
     * @{inherit}
     */
    public function new(?resolves:Int = 1):Void
    {
        super(resolves);

        this.thens   = new Deque<Callback<T>>();
        this.waiters = new Deque<Thread>();
        this.mutex   = new Mutex();
    }

    /**
     * @{inherit}
     */
    override public function await():Void
    {
        if (!this.isDone) {
            this.waiters.add(Thread.current());
            var msg:Dynamic = Thread.readMessage(true);
            while (msg != Signal.READY) {
                msg = Thread.readMessage(true);
            }
        }
    }

    /**
     * @{inherit}
     */
    override private function executeCallbacks(args:T):Void
    {
        var callback:Callback<T>;
        while ((callback = this.thens.pop(false)) != null) {
            try {
                callback(args);
            } catch (ex:Dynamic) {
                // CallbackException
            }
        }
    }

    /**
     * @{inherit}
     */
    override private function get_isDone():Bool
    {
        this.mutex.acquire();
        var done:Bool = this.resolves <= 0 && (this.isRejected || this.isResolved);
        this.mutex.release();

        return done;
    }

    /**
     * Notifies all waiting threads that the Promise has been marked as done.
     *
     * @param Signal signal the signal to send to the waiting threads
     */
    private function notifyWaiters(signal:Signal):Void
    {
        var waiter:Thread;
        while ((waiter = this.waiters.pop(false)) != null) {
            waiter.sendMessage(signal);
        }
    }

    /**
     * @{inherit}
     */
    override public function reject():Void
    {
        this.mutex.acquire();
        var done:Bool = this.resolves <= 0 && (this.isRejected || this.isResolved);
        if (!done) {
            this.isRejected = true;
            this.notifyWaiters(Signal.READY); // stop blocking
        }
        this.mutex.release();

        if (done) {
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function resolve(args:T):Void
    {
        this.mutex.acquire();
        var done:Bool = this.resolves <= 0 && (this.isRejected || this.isResolved);
        if (!done) {
            if (--this.resolves <= 0) {
                this.executeCallbacks(args);
                this.isResolved = true;
                this.notifyWaiters(Signal.READY); // stop blocking
            }
        }
        this.mutex.release();

        if (done) {
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function then(callback:Callback<T>):Void
    {
        if (!this.isDone) {
            this.thens.push(callback);
        } else {
            throw new WorkflowException("Promise has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    public static function when<T>(promises:Array<Promise<T>>):Promise<T>
    {
        var hasUnresolved:Bool = false;
        var promise:Promise<T> = new Promise<T>(0);
        var done:Bool;
        for (p in promises) {
            p.mutex.acquire();
            done = p.resolves <= 0 && (p.isRejected || p.isResolved);
            if (!done) {
                hasUnresolved = true;
                ++promise.resolves;
                p.thens.push(function(args:T):Void {
                    promise.resolve(args);
                });
            }
            p.mutex.release();
        }

        if (hasUnresolved) {
            throw new WorkflowException("Promises have already been rejected or resolved");
        }

        return promise;
    }
}
