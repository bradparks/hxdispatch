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
        this.resolves   = resolves;
        this.mutex      = new Mutex();
        this.thread     = Thread.create(function():Void {
            var state:State = State.WAITING;
            var parent:Thread = Thread.readMessage(true);
            while (state == State.WAITING) {
                var remaining:Int = Thread.readMessage(true);
                if (remaining == 0) {
                    this.isResolved = true;
                    state = State.DONE;
                } else if (remaining == -1) {
                    this.isRejected = true;
                    state = State.DONE;
                }
            }
            parent.sendMessage(state);
        });
        this.thread.sendMessage(Thread.current());

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
        while (Thread.readMessage(true) != State.DONE) {
            // || this.resolves < -1 -> error
        }
    }
}


private enum State
{
    DONE;
    WAITING;
}
