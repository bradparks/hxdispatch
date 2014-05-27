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
     * @var hxstd.vm.Mutex
     */
    private var mutex:Mutex;

    /**
     * Stores the Lock used to block get() callers.
     *
     * @var hxstd.vm.MultLock
     */
    private var lock:MultiLock;

    /**
     * Stores the number of waiters (having called await).
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

        this.mutex   = new Mutex();
        this.lock    = new MultiLock();
        this.waiters = 0;
    }

    /**
     * @{inherit}
     */
    override public function get(block:Bool = true):Null<T>
    {
        this.mutex.acquire();
        if (this.state == State.NONE) {
            if (block) {
                ++this.waiters;
                this.mutex.release();
                this.lock.wait();
                --this.waiters;

                return this.value;
            } else {
                this.mutex.release();
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
        this.mutex.acquire();
        var ret:Bool = this.state != State.NONE;
        this.mutex.release();

        return ret;
    }

    /**
     * @{inherit}
     */
    override public function isRejected():Bool
    {
        this.mutex.acquire();
        var ret:Bool = this.state == State.REJECTED;
        this.mutex.release();

        return ret;
    }

    /**
     * @{inherit}
     */
    override public function isResolved():Bool
    {
        this.mutex.acquire();
        var ret:Bool = this.state == State.RESOLVED;
        this.mutex.release();

        return ret;
    }

    /**
     * Unlocks the Lock that is used to block waiters in get() method.
     */
    private function unlock():Void
    {
        this.mutex.acquire();
        while (this.waiters != 0) {
            this.lock.release();
        }
        this.mutex.release();
    }

    /**
     * @{inherit}
     */
    override public function reject():Void
    {
        this.mutex.acquire();
        if (this.state == State.NONE) {
            this.state = State.REJECTED;
            this.unlock();
            this.mutex.release();
        } else {
            this.mutex.release();
            throw new WorkflowException("Future has already been rejected or resolved");
        }
    }

    /**
     * @{inherit}
     */
    override public function resolve(value:T):Void
    {
        this.mutex.acquire();
        if (this.state == State.NONE) {
            this.value = value;
            this.state = State.RESOLVED;
            this.unlock();
            this.mutex.release();
        } else {
            this.mutex.release();
            throw new WorkflowException("Future has already been rejected or resolved");
        }
    }
}
