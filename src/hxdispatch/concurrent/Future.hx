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
        try {
            var value:T = super.get(block);
        } catch (ex:Dynamic) {
            this.mutex.release();
            throw ex;
        }
        this.mutex.release();

        return value;
    }

    /**
     * @{inherit}
     */
    override public function isReady():Bool
    {
        this.mutex.acquire();
        var ret:Bool = super.isReady();
        this.mutex.release();

        return ret;
    }

    /**
     * @{inherit}
     */
    override public function isRejected():Bool
    {
        this.mutex.acquire();
        var ret:Bool = super.isRejected();
        this.mutex.release();

        return ret;
    }

    /**
     * @{inherit}
     */
    override public function isResolved():Bool
    {
        this.mutex.acquire();
        var ret:Bool = super.isResolved();
        this.mutex.release();

        return ret;
    }

    /**
     * @{inherit}
     */
    override public function reject():Void
    {
        this.mutex.acquire();
        try {
            super.reject();
        } catch (ex:Dynamic) {
            this.mutex.release();
            throw ex;
        }
        this.mutex.release();
    }

    /**
     * @{inherit}
     */
    override public function resolve(value:T):Void
    {
        this.mutex.acquire();
        try {
            super.resolve(value);
        } catch (ex:Dynamic) {
            this.mutex.release();
            throw ex;
        }
        this.mutex.release();
    }
}
