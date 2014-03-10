package hxdispatch;

/**
 *
 */
@:generic
class Future<T>
{
    private var value:T;

    public var isReady(get, never):Bool;
    public var isRejected(default, null):Bool;
    public var isResolved(default, null):Bool;

    /**
     *
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
     *
     */
    public function get(?block:Bool = true):T
    {
        if (this.isReady) {
            return this.value;
        }

        throw "Future has not been resolved yet";
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
    public function reject():Void
    {
        if (!this.isReady) {
            this.isRejected = true;
        } else {
            throw "Future has already been rejected or resolved";
        }
    }

    /**
     *
     */
    public function resolve(value:T):Void
    {
        if (!this.isReady) {
            this.value      = value;
            this.isResolved = true;
        } else {
            throw "Future has already been resolved";
        }
    }
}
