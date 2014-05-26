package hxdispatch.concurrent;

import hxdispatch.State;
import hxdispatch.WorkflowException;
import hxstd.vm.MultiLock;
import hxstd.vm.Mutex;

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
     * @var { state:hxstd.vm.Mutex, waiters:hxstd.vm.Mutex }
     */
    private var mutex:{ state:Mutex, waiters:Mutex };

    /**
     * Stores the Lock used to block get() callers.
     *
     * @var hxstd.vm.MultLock
     */
    private var lock:MultiLock;

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
        this.lock    = new MultiLock();
        this.waiters = 0;
    }

    /**
     * @{inherit}
     */
    override public function get(?block:Bool = true):Null<T>
    {
        this.mutex.state.acquire();
        if (this.state == State.NONE) {
            if (block) {
                this.mutex.waiters.acquire();
                ++this.waiters;
                this.mutex.state.release();
                this.mutex.waiters.release();
                this.lock.wait();

                return this.value;
            } else {
                this.mutex.state.release();
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
        this.lock.release();
        this.mutex.waiters.release();
    }

    /**
     * @{inherit}
     */
    override public function reject():Void
    {
        this.mutex.state.acquire();
        if (this.state == State.NONE) {
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
        if (this.state == State.NONE) {
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
