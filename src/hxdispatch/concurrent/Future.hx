package hxdispatch.concurrent;

import hxdispatch.State;
import hxdispatch.WorkflowException;
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
     * @{inherit}
     */
    public function new():Void
    {
        super();
        this.mutex = new Mutex();
    }

    /**
     * @{inherit}
     */
    override public function get(block:Bool = true):T
    {
        this.mutex.acquire();
        if (!this.isReady()) {
            this.mutex.release();
            throw new WorkflowException("Future has not been resolved yet");
        }
        this.mutex.acquire();

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
     * @{inherit}
     */
    override public function reject():Void
    {
        this.mutex.acquire();
        if (this.state == State.NONE) {
            this.state = State.REJECTED;
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
            this.mutex.release();
        } else {
            this.mutex.release();
            throw new WorkflowException("Future has already been rejected or resolved");
        }
    }
}
