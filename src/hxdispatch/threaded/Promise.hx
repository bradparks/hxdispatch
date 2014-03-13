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
class Promise<T> extends hxdispatch.Promise<T>
{
    private var thens:Deque<Callback<T>>;
    private var waiters:Deque<Thread>;
    private var mutex:Mutex;

    /**
     *
     */
    public function new(?resolves:Int = 1):Void
    {
        super(resolves);

        this.thens   = new Deque<Callback<T>>();
        this.waiters = new Deque<Thread>();
        this.mutex   = new Mutex();
    }

    /**
     *
     */
    override public function await():Void
    {
        if (!this.isReady) {
            this.waiters.add(Thread.current());
            var msg:Dynamic = Thread.readMessage(true);
            while (msg != Signal.READY) {
                msg = Thread.readMessage(true);
            }
        }
    }

    /**
     *
     */
    override public function get_isReady():Bool
    {
        this.mutex.acquire();
        var ready:Bool = this.resolves <= 0 && (this.isRejected || this.isResolved);
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
        var ready:Bool = this.resolves <= 0 && (this.isRejected || this.isResolved);
        if (!ready) {
            this.isRejected = true;
            this.notifyWaiters(Signal.READY); // stop blocking
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
        var ready:Bool = this.resolves <= 0 && (this.isRejected || this.isResolved);
        if (!ready) {
            if (--this.resolves <= 0) {
                this.executeCallbacks(args);
                this.isResolved = true;
                this.notifyWaiters(Signal.READY); // stop blocking
            }
        }
        this.mutex.release();

        if (ready) {
            throw "Promise has already been rejected or resolved";
        }
    }

    /**
     * @see https://github.com/jdonaldson/promhx where I have stolen the idea
     */
    public static function when<T>(promises:Array<Promise<T>>):Promise<T>
    {
        var hasUnresolved:Bool = false;
        var promise:Promise<T> = new Promise<T>(0);
        var ready:Bool;
        for (p in promises) {
            p.mutex.acquire();
            ready = p.resolves <= 0 && (p.isRejected || p.isResolved);
            if (!ready) {
                hasUnresolved = true;
                promise.resolves += 1;
                p.then(function(args:T):Void {
                    promise.resolve(args);
                });
            }
            p.mutex.release();
        }

        if (hasUnresolved) {
            throw "Promises have already been rejected or resolved";
        }

        return promise;
    }
}
