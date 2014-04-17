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
    #error "Concurrent Future is not supported on target platform due to the lack of Lock/Mutex feature."
#end
import hxdispatch.State;
import hxdispatch.WorkflowException;

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
    /**
     * Stores the Mutex used to synchronize access to properties.
     *
     * @var { state:Mutex, waiters:Mutex }
     */
    private var mutex:{ state:Mutex, waiters:Mutex };

    /**
     * Stores the Lock used to block get() callers.
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
    public function new():Void
    {
        super();
        this.mutex   = { state: new Mutex(), waiters: new Mutex() }
        this.lock    = new Lock();
        this.waiters = 0;
    }

    /**
     * @{inherit}
     */
    override public function get(?block:Bool = true):Null<T>
    {
        if (!this.isReady()) {
            if (block) {
                this.mutex.waiters.acquire();
                ++this.waiters;
                this.mutex.waiters.release();
                this.lock.wait();

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
    override public function isReady():Bool
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
     * Unlocks the Lock that is used to block waiters in get() method.
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
    override public function reject():Void
    {
        this.mutex.state.acquire();
        var ready:Bool = this.state != State.NONE;
        if (!ready) {
            this.state = State.REJECTED;
            this.mutex.state.release();
            this.unlock(this.waiters);
        } else {
            this.mutex.state.release();
            throw new WorkflowException("Future has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function resolve(value:T):Void
    {
        this.mutex.state.acquire();
        var ready:Bool = this.state != State.NONE;
        if (!ready) {
            this.value = value;
            this.state = State.RESOLVED;
            this.mutex.state.release();
            this.unlock(this.waiters);
        } else {
            this.mutex.state.release();
            throw new WorkflowException("Future has already been rejected or resolved");
        }
    }
}
