package hxdispatch;

import hxdispatch.Callback;

/**
 *
 */
 @:generic
class Promise<T>
{
    private var callbacks:Array<Callback<T>>;
    private var resolves:Int;

    public var isReady(get, never):Bool;
    public var isRejected(default, null):Bool;
    public var isResolved(default, null):Bool;

    /**
     *
     */
    public function new(?resolves:Int = 1):Void
    {
        this.callbacks  = new Array<Callback<T>>();
        this.resolves   = resolves;
        this.isRejected = false;
        this.isResolved = false;
    }

    /**
     *
     */
    public function await():Void
    {
        throw "await() not supported in non-threaded Promise";
    }

    /**
     *
     */
    public function get_isReady():Bool
    {
        return this.resolves <= 0 && (this.isRejected || this.isResolved);
    }

    /**
     *
     */
    private function executeCallbacks(args:T):Void
    {
        var callback:Callback<T>;
        for (callback in this.callbacks) {
            callback(args);
        }
    }

    /**
     *
     */
    public function reject():Void
    {
        if (!this.isReady) {
            this.isRejected = true;
        } else {
            throw "Promise has already been rejected or resolved";
        }
    }

    /**
     *
     */
    public function resolve(args:T):Void
    {
        if (!this.isReady) {
            if (--this.resolves == 0) {
                this.executeCallbacks(args);
                this.isResolved = true;
            }
        } else {
            throw "Promise has already been rejected or resolved";
        }
    }

    /**
     *
     */
    public function then(callback:Callback<T>):Void
    {
        if (!this.isReady) {
            this.callbacks.push(callback);
        } else {
            throw "Promise has already been rejected or resolved";
        }
    }
}
