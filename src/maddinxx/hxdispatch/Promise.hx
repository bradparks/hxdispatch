package maddinxx.hxdispatch;

#if cpp
import cpp.vm.Mutex;
import cpp.vm.Thread;
#elseif java
import java.vm.Mutex;
import java.vm.Thread;
#elseif neko
import neko.vm.Mutex;
import neko.vm.Thread;
#end

/**
 * The Promise is returns by triggered Events and allows
 * waiting for the callbacks.
 */
class Promise
{
    private var resolves:Int;
    #if (cpp || java || neko)
    private var mutex:Mutex;
    private var thread:Thread;
    #end
    private var thens:Array<Then>;

    public var isDone(get, never):Bool;
    public var isRejected(default, null):Bool;
    public var isResolved(default, null):Bool;

    public function new(?resolves:Int = 1):Void
    {
        this.resolves = resolves;
        #if (cpp || java || neko)
        this.mutex    = new Mutex();
        this.thread   = Thread.current();
        #end
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
     * Returns either the Promise is done (e.g. no more await required) or not.
     *
     * @return Bool
     */
    public function get_isDone():Bool
    {
        return this.resolves <= 0 && this.isResolved != this.isRejected;
    }

    /**
     * Rejects the promise.
     */
    public function reject():Void
    {
        #if (cpp || java || neko)
        this.mutex.acquire();
        this.thread.sendMessage(this.resolves = -1);
        this.mutex.release();
        #elseif js
        this.resolves = -1;
        #end
    }

    /**
     * Resolves the promise.
     * The wait() method is only resolved, if it was the last resolve required.
     */
    public function resolve():Void
    {
        #if (cpp || java || neko)
        this.mutex.acquire();
        this.thread.sendMessage(--this.resolves);
        this.mutex.release();
        #elseif js
        --this.resolves;
        #end
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
    public function await():Void
    {
        #if (cpp || java || neko)
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
        #elseif js
        // TODO
        #end

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
