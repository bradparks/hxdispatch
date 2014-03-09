package hxdispatch.threaded;

#if cpp
    import cpp.vm.Mutex;
    import cpp.vm.Thread;
#elseif java
    import java.vm.Mutex;
    import java.vm.Thread;
#elseif neko
    import neko.vm.Mutex;
    import neko.vm.Thread;
#else
    #error "Threaded future is not supported on target platform due to the lack of Mutex/Thread feature."
#end

/**
 *
 */
@:generic
class Future<T> extends hxdispatch.Future<T>
{
    private var thread:Thread;
    private var mutex:Mutex;

    /**
     *
     */
    public function new():Void
    {
        super();

        this.thread = Thread.current();
        this.mutex  = new Mutex();
    }

    /**
     *
     */
    override public function get(?block:Bool = false):T
    {
        if (!this.isReady) {
            if (block) {
                if (Thread.current() == this.thread) { // TODO: never entered
                    var msg:Dynamic = Thread.readMessage(true);
                    while (msg != Signal.READY) {
                        msg = Thread.readMessage(true);
                    }
                } else {
                    while (!this.isReady) {
                        Sys.sleep(0.01); // TODO: magic number
                    }
                }
                return this.value;
            } else {
                throw "Future has not been resolved yet";
            }
        }

        return this.value;
    }

    /**
     *
     */
    override public function get_isReady():Bool
    {
        this.mutex.acquire();
        var ready:Bool = this.isRejected || this.isResolved;
        this.mutex.release();
        return ready;
    }

    /**
     *
     */
    override public function reject():Void
    {
        this.mutex.acquire();
        var ready:Bool = this.isRejected || this.isResolved;
        if (!ready) {
            this.isRejected = true;
            this.thread.sendMessage(Signal.READY); // stop blocking
        }
        this.mutex.release();

        if (ready) {
            throw "Future has already been rejected or resolved";
        }
    }

    /**
     *
     */
    override public function resolve(value:T):Void
    {
        this.mutex.acquire();
        var ready:Bool = this.isRejected || this.isResolved;
        if (!ready) {
            this.value      = value;
            this.isResolved = true;
            this.thread.sendMessage(Signal.READY); // stop blocking
        }
        this.mutex.release();

        if (ready) {
            throw "Future has already been rejected or resolved";
        }
    }

    /**
     * Allows setting the receiving thread of the READY signal.
     *
     * Since we can't assume the main thread is waiting for the value (get())
     * we have to frequently pull the isResolved property so we don't miss the READY
     * signal.
     * As this is done with a Sys.sleep() in between, setting the receiver will bypass the delay.
     *
     * @param Thread thread the receiving thread
     */
    public function toNotify(thread:Thread):Void
    {
        if (!this.isReady) {
            this.thread = thread;
        } else {
            throw "Future has already been rejected or resolved";
        }
    }
}


/**
 *
 */
private enum Signal
{
    READY;
}
