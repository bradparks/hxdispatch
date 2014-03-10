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
    #error "Threaded Future is not supported on target platform due to the lack of Deque/Mutex/Thread feature."
#end
import hxdispatch.threaded.Signal;

/**
 *
 */
@:generic
class Future<T> extends hxdispatch.Future<T>
{
    private var waiters:Deque<Thread>;
    private var mutex:Mutex;

    /**
     *
     */
    public function new():Void
    {
        super();

        this.waiters = new Deque<Thread>();
        this.mutex   = new Mutex();
    }

    /**
     *
     */
    override public function get(?block:Bool = true):T
    {
        if (!this.isReady) {
            if (block) {
                this.waiters.add(Thread.current());
                var msg:Dynamic = Thread.readMessage(true);
                while (msg != Signal.READY) {
                    msg = Thread.readMessage(true);
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
    private function notifyWaiters(signal:Signal):Void
    {
        var waiter:Thread;
        while ((waiter = this.waiters.pop(false)) != null) {
            waiter.sendMessage(signal);
        }
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
            this.notifyWaiters(Signal.READY); // stop blocking
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
            this.notifyWaiters(Signal.READY); // stop blocking
        }
        this.mutex.release();

        if (ready) {
            throw "Future has already been rejected or resolved";
        }
    }
}
