package maddinxx.hxdispatch;

#if cpp
    import cpp.vm.Mutex;
    import cpp.vm.Thread;
#elseif neko
    import neko.vm.Mutex;
    import neko.vm.Thread;
#else
    #error "ThreadedDispatcher not supported on target platform due to missing Mutex/Thread support. Please use Dispatcher instead."
#end
import maddinxx.hxdispatch.Args;
import maddinxx.hxdispatch.Callback;
import maddinxx.hxdispatch.Promise;
import maddinxx.hxdispatch.SyncedDispatcher;

/**
 * The threaded event dispatcher starts one thread per callback and does not wait
 * for them before it returns a result, thus is async.
 */
class ThreadedDispatcher extends SyncedDispatcher
{
    /**
     * @{inheritDoc}
     */
    override public function trigger(event:String, ?args:Args):Null<Promise>
    {
        if (this.hasEvent(event)) {
            this.mutex.acquire();
            var callbacks:Array<Callback> = this.eventMap.get(event).copy();
            this.mutex.release();

            var thread:Thread;
            var promise = new Promise(callbacks.length);

            var callback:Callback;
            for (callback in callbacks) {
                thread = Thread.create(function():Void {
                    callback(args);
                    promise.resolve();
                });
            }

            if (event != "_eventTriggered") {
                var subpromis:Promise = this.trigger("_eventTriggered", { event: event, args: args });
                if (subpromis != null) {
                    subpromis.wait();
                }
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

            return promise;
        }

        return null;
    }
}
