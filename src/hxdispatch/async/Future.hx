package hxdispatch.async;

import hxdispatch.State;
import hxdispatch.WorkflowException;
import hxstd.vm.MultiLock;

/**
 * Asynchronous Future implementation.
 *
 * @{inherit}
 */
class Future<T> extends hxdispatch.concurrent.Future<T>
{
    /**
     * Stores the Lock used to block get() callers.
     *
     * @var hxstd.vm.MultLock
     */
    private var lock:MultiLock;


    /**
     * @{inherit}
     */
    public function new():Void
    {
        super();
        this.lock  = new MultiLock();
    }

    /**
     * @{inherit}
     */
    override public function get(block:Bool = true):Null<T>
    {
        this.mutex.acquire();
        if (!this.isReady()) {
            if (block) {
                this.mutex.release();
                while (!this.lock.wait(0.001) && !this.isReady()) {}

                return this.value;
            } else {
                this.mutex.release();
                throw new WorkflowException("Future has not been resolved yet");
            }
        }

        return this.value;
    }

    /**
     * Unlocks the Lock that is used to block waiters in get() method.
     */
    private function unlock():Void
    {
        this.mutex.acquire();
        this.lock.release();
        this.mutex.release();
    }

    /**
     * @{inherit}
     */
    override public function reject():Void
    {
        super.reject();
        this.unlock();
    }

    /**
     * @{inherit}
     */
    override public function resolve(value:T):Void
    {
        super.resolve(value);
        this.unlock();
    }
}
