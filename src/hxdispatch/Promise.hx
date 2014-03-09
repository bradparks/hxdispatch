package hxdispatch;

/**
 *
 */
 @:generic
class Promise<T>
{
    private var callbacks:Array<Callback<T>>;

    public var isReady(get, never):Bool;
    public var isRejected(default, null):Bool;
    public var isResolved(default, null):Bool;

    /**
     *
     */
    public function new():Void
    {
        this.callbacks  = new Array<Callback<T>>();
        this.isRejected = false;
        this.isResolved = false;
    }

    /**
     *
     */
    public function get_isReady():Bool
    {
        return this.isRejected || this.isResolved;
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
            this.isResolved = true;
            this.executeCallbacks(args);
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


/**
 *
 */
private typedef Callback<T> = T->Void;
