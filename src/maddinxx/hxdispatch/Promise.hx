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
    private var thens:Array<Then>;

    public var isRejected(default, null):Bool;
    public var isResolved(default, null):Bool;

    public function new(?resolves:Int = 1):Void
    {
        this.resolves = resolves;
        this.mutex    = new Mutex();
        this.thread   = Thread.current();
        this.thens    = new Array<Then>();

        this.isRejected = false;
        this.isResolved = false;
    }

    /**
     * Executes the registered callbacks after the Promise
     * has been resolved or rejected.
     */
    private function executeThens():Void
    {
        var callback:Then;
        for (callback in this.thens) {
            callback();
        }
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
     * Adds the callback function to the then event which is
     * raised when the promise has been resolved or rejected.
     */
    public function then(callback:Then):Void
    {
        // thens are called synchronized. if you want to have them async as well,
        // the recommended way is to define another ThreadedDispatcher and add callbacks,
        // then trigger the event after the Promise has been resolved...so after wait()
        this.thens.push(callback);
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

        if (this.thens.length != 0) {
            this.executeThens();
        }
    }
}


private enum Signal
{
    DONE;
}


private typedef Then = Void->Void;
