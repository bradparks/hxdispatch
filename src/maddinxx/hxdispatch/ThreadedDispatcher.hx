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
#elseif !js
#error "ThreadedDispatcher not supported on target platform due to missing Mutex/Thread support. Please use Dispatcher instead."
#end
import maddinxx.hxdispatch.Args;
import maddinxx.hxdispatch.Callback;
import maddinxx.hxdispatch.Feedback;
import maddinxx.hxdispatch.Feedback.Status;
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
    override public function trigger(event:String, ?args:Args):Feedback
    {
        if (this.hasEvent(event)) {
            #if (cpp || java || neko)
            this.mutex.acquire();
            #end
            var callbacks:Array<Callback> = this.eventMap.get(event).copy();
            #if (cpp || java || neko)
            this.mutex.release();
            #end

            var promise = new Promise(callbacks.length);
            var callback:Callback;
            #if (cpp || java || neko)
            var thread:Thread;
            for (callback in callbacks) {
                thread = Thread.create(function():Void {
                    callback(args);
                    promise.resolve();
                });
            }
            #elseif js
            for (callback in callbacks) {
                if (Reflect.isFunction(callback)) {
                    var js_callback:Callback = callback;
                    var js_args:Args         = args;
                    untyped __js__("setTimeout(function ()
                    {
                        js_callback(js_args);
                        promise.resolve();
                    }, 0)");
                }
            }
            #end

            if (event != "_eventTriggered") {
                var feedback:Feedback = this.trigger("_eventTriggered", { event: event, args: args });
                if (feedback.status == Status.TRIGGERED && !feedback.promise.isDone) {
                    feedback.promise.await();
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

            return { status: Status.TRIGGERED, promise: promise };
        }

        return { status: Status.NO_SUCH_EVENT };
    }
}
