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
    #error "Threaded Future is not supported on target platform due to the lack of Deque/Mutex/Thread feature."
#end
import hxdispatch.WorkflowException;
import hxdispatch.threaded.Signal;

/**
 * Thread-safe Future implementation.
 *
 * This version can be rejected/resolved by other threads and been awaited by them
 * as well (even by multiple threads).
 *
 * @{inherit}
 */
class Future<T> extends hxdispatch.Future<T>
{
    private var waiters:Deque<Thread>;
    private var mutex:Mutex;

    /**
     * @{inherit}
     */
    public function new():Void
    {
        super();

        this.waiters = new Deque<Thread>();
        this.mutex   = new Mutex();
    }

    /**
     * @{inherit}
     */
    override public function get(?block:Bool = true):T
    {
        if (!this.isReady) {
            if (block) {
                this.waiters.add(Thread.current());
                var msg:Dynamic = Thread.readMessage(true);
                while (msg != Signal.READY) {
                    msg = Thread.readMessage(true);
                }
                return this.value;
            } else {
                throw new WorkflowException("Future has not been resolved yet");
            }
        }

        return this.value;
    }

    /**
     * @{inherit}
     */
    override private function get_isReady():Bool
    {
        this.mutex.acquire();
        var ready:Bool = this.isRejected || this.isResolved;
        this.mutex.release();

        return ready;
    }

    /**
     * @{inherit}
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
        var ready:Bool = this.isRejected || this.isResolved;
        if (!ready) {
            this.isRejected = true;
            this.notifyWaiters(Signal.READY); // stop blocking
        }
        this.mutex.release();

        if (ready) {
            throw new WorkflowException("Future has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function resolve(value:T):Void
    {
        this.mutex.acquire();
        var ready:Bool = this.isRejected || this.isResolved;
        if (!ready) {
            this.value      = value;
            this.isResolved = true;
            this.notifyWaiters(Signal.READY); // stop blocking
        }
        this.mutex.release();

        if (ready) {
            throw new WorkflowException("Future has already been rejected or resolved");
        }
    }
}
