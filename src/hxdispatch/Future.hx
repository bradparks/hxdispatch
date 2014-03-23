package hxdispatch;

import hxdispatch.WorkflowException;

/**
 * A Future can be understood as a pledge that it will contain a
 * valid value at some time (that is not right now).
 *
 * This is useful if you know that you some data will somewhen be available
 * but you are not sure when (but need to wait for it).
 *
 * This version is not thread safe and therefor not of much use, as it will
 * simply throw an error when the Future's value has not been set yet.
 *
 * @generic T the type of value you expect
 */
class Future<T>
{
    private var value:T;

    public var isReady(get, never):Bool;
    public var isRejected(default, null):Bool;
    public var isResolved(default, null):Bool;

    /**
     * Constructor to initialize a new Future.
     */
    public function new():Void
    {
        #if (!cpp && !java)
            this.value  = null;
        #end
        this.isRejected = false;
        this.isResolved = false;
    }

    /**
     * Returns the value once it is set.
     *
     * @param Bool block either to wait until a value is set or not
     *
     * @return T the value set
     *
     * @throws String if the future has not been resolved yet (since the non-threaded version can't wait)
     */
    public function get(?block:Bool = true):T
    {
        if (this.isReady) {
            return this.value;
        }

        throw new WorkflowException("Future has not been resolved yet");
    }

    /**
     * Internal method for the isReady property to check if the Future's value
     * has been set yet.
     *
     * @return Bool true if value is set
     */
    private function get_isReady():Bool
    {
        return this.isRejected || this.isResolved;
    }

    /**
     * Rejects the Future, thus marking it as "failed".
     *
     * @throws String if the future has already been marked as ready
     */
    public function reject():Void
    {
        if (!this.isReady) {
            this.isRejected = true;
        } else {
            throw new WorkflowException("Future has already been rejected or resolved");
        }
    }

    /**
     * Resolves the Future by setting its value to the provided value.
     *
     * @param T value the value to set
     *
     * @throws String if the future has already been marked as ready
     */
    public function resolve(value:T):Void
    {
        if (!this.isReady) {
            this.value      = value;
            this.isResolved = true;
        } else {
            throw new WorkflowException("Future has already been resolved");
        }
    }
}
