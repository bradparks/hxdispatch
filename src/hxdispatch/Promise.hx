package hxdispatch;

import hxdispatch.Callback;

/**
 *
 */
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
            if (--this.resolves <= 0) {
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

    /**
     * @see https://github.com/jdonaldson/promhx where I have stolen the idea
     */
    public static function when<T>(promises:Array<Promise<T>>):Promise<T>
    {
        var promise:Promise<T> = new Promise<T>(0);
        for (p in promises) {
            if (!p.isReady) {
                promise.resolves += 1;
                p.then(function(args:T):Void {
                    promise.resolve(args);
                });
            }
        }

        return promise;
    }
}
