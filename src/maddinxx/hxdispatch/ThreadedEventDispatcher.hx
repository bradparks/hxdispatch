package maddinxx.hxdispatch;

#if cpp
    import cpp.vm.Mutex;
    import cpp.vm.Thread;
#elseif neko
    import neko.vm.Mutex;
    import neko.vm.Thread;
#else
    #error "SynchronizedEventDispatcher not supported on target platform due to missing Mutex/Thread support. Please use EventDispatcher instead."
#end
import maddinxx.hxdispatch.EventArgs;
import maddinxx.hxdispatch.EventCallback;
import maddinxx.hxdispatch.SynchronizedEventDispatcher;

/**
 * The threaded event dispatcher starts one thread per callback and does not wait
 * for them before it returns a result, thus is async.
 */
class ThreadedEventDispatcher extends SynchronizedEventDispatcher
{
    /**
     * @{inheritDoc}
     */
    override public function trigger(event:String, ?args:EventArgs):Bool
    {
        if (this.hasEvent(event)) {
            this.mutex.acquire();
            var callbacks:Array<EventCallback> = this.eventMap.get(event).copy();
            this.mutex.release();

            var thread:Thread;
            var promise:Thread = Thread.create(function():Void {
                var dispatcher = Thread.readMessage(true);
                for (i in 0...callbacks.length) {
                    Thread.readMessage(true);
                }
                //Sys.sleep(0.05); // Magic number so main thread is at waiting position
                //dispatcher.sendMessage(null);
            });
            promise.sendMessage(Thread.current()); // activate promise

            var callback:EventCallback;
            for (callback in callbacks) {
                thread = Thread.create(function():Void {
                    var promise:Thread = Thread.readMessage(true);
                    callback(args);
                    promise.sendMessage(null);
                });
                thread.sendMessage(promise); // activate callback thread
            }

            if (event != "_eventTriggered") {
                this.trigger("_eventTriggered", { event: event, args: args });
            }

            // Alternative way with one thread calling all callbacks
            // var worker:Thread = Thread.create(function():Void {
            //     var dispatcher = Thread.readMessage(true);
            //     for (callback in callbacks) {
            //         callback(args);
            //     }
            //     dispatcher.sendMessage(null);
            // });
            // worker.sendMessage(Thread.current());

            //Thread.readMessage(true); // PROBLEM: when promise writes before we get here we will never receive the signal

            return true;
        }

        return false;
    }
}
