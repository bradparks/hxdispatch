package maddinxx.hxdispatch;

#if cpp
    import cpp.vm.Mutex;
    import cpp.vm.Thread;
#elseif neko
    import neko.vm.Mutex;
    import neko.vm.Thread;
#else
    #error "Promise not supported on target platform due to missing Mutex/Thread support."
#end

/**
 * The Promise is returns by triggered Events and allows
 * waiting for the callbacks.
 */
class Promise
{
    private var resolves:Int;
    private var mutex:Mutex;
    private var thread:Thread;

    public var isRejected(default, null):Bool;
    public var isResolved(default, null):Bool;

    public function new(?resolves:Int = 1):Void
    {
        this.resolves = resolves;
        this.mutex    = new Mutex();
        this.thread   = Thread.current();

        this.isRejected = false;
        this.isResolved = false;
    }

    /**
     * Rejects the promise.
     */
    public function reject():Void
    {
        this.mutex.acquire();
        this.thread.sendMessage(this.resolves = -1);
        this.mutex.release();
    }

    /**
     * Resolves the promise.
     * The wait() method is only resolved, if it was the last resolve required.
     */
    public function resolve():Void
    {
        this.mutex.acquire();
        this.thread.sendMessage(--this.resolves);
        this.mutex.release();
    }

    /**
     * Blocks the thread/execution until the promise was either
     * resolved or rejected.
     */
    public function wait():Void
    {
        var msg:Dynamic = Thread.readMessage(true);
        while (msg != Signal.DONE) {
            msg = cast(msg, Int);
            if (msg == 0) {
                this.isResolved = true;
                msg = Signal.DONE;
            } else if (msg == -1) {
                this.isRejected = true;
                msg = Signal.DONE;
            } else {
                msg = Thread.readMessage(true);
            }
        }
    }
}


private enum Signal
{
    DONE;
}
