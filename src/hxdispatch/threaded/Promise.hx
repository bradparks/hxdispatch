package hxdispatch.threaded;

#if cpp
    import cpp.vm.Deque;
    import cpp.vm.Mutex;
    import cpp.vm.Thread;
#elseif java
    import java.vm.Deque;
    import java.vm.Mutex;
    import java.vm.Thread;
#elseif neko
    import neko.vm.Deque;
    import neko.vm.Mutex;
    import neko.vm.Thread;
#else
    #error "Threaded Promise is not supported on target platform due to the lack of Deque/Mutex/Thread feature."
#end
import hxdispatch.Callback;
import hxdispatch.threaded.Signal;

/**
 *
 */
@:generic
class Promise<T> extends hxdispatch.Promise<T>
{
    private var thens:Deque<Callback<T>>;
    private var thread:Thread;
    private var mutex:Mutex;

    /**
     *
     */
    public function new(?resolves:Int = 1):Void
    {
        super(resolves);

        this.thens  = new Deque<Callback<T>>();
        this.thread = Thread.current();
        this.mutex  = new Mutex();
    }

    /**
     *
     */
    override public function await(?block:Bool = true):Void
    {
        if (!this.isReady && block) {
            if (Thread.current() == this.thread) { // TODO: never entered
                var msg:Dynamic = Thread.readMessage(true);
                while (msg != Signal.READY) {
                    msg = Thread.readMessage(true);
                }
            } else {
                while (!this.isReady) {
                    Sys.sleep(0.005); // TODO: magic number
                }
            }
        }
    }

    /**
     *
     */
    public function block():Void
    {
        return this.await(true);
    }

    /**
     *
     */
    override public function get_isReady():Bool
    {
        this.mutex.acquire();
        var ready:Bool = this.resolves == 0 && (this.isRejected || this.isResolved);
        this.mutex.release();
        return ready;
    }

    /**
     *
     */
    override public function reject():Void
    {
        this.mutex.acquire();
        var ready:Bool = this.resolves == 0 && (this.isRejected || this.isResolved);
        if (!ready) {
            this.isRejected = true;
            this.thread.sendMessage(Signal.READY); // stop blocking
        }
        this.mutex.release();

        if (ready) {
            throw "Promise has already been rejected or resolved";
        }
    }

    /**
     *
     */
    override public function resolve(args:T):Void
    {
        this.mutex.acquire();
        var ready:Bool = this.resolves == 0 && (this.isRejected || this.isResolved);
        if (!ready) {
            if (--this.resolves == 0) {
                this.executeCallbacks(args);
                this.isResolved = true;
                this.thread.sendMessage(Signal.READY); // stop blocking
            }
        }
        this.mutex.release();

        if (ready) {
            throw "Promise has already been rejected or resolved";
        }
    }

    /**
     * Allows setting the receiving thread of the READY signal.
     *
     * Since we can't assume the main thread is waiting for the reject/resolve (await())
     * we have to frequently pull the isReady property so we don't miss the READY
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
            throw "Promise has already been rejected or resolved";
        }
    }
}
