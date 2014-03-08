package maddinxx.hxdispatch;

#if cpp
import cpp.vm.Mutex;
import cpp.vm.Thread;
#elseif java
import java.vm.Mutex;
import java.vm.Thread;
#elseif js
import haxe.Timer;
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
    override private function runCallback(callback:Callback, args:Null<Args>):Void
    {
        #if (cpp || java || neko)
        Thread.create(function():Void {
            callback(args);
        });
        #elseif js
        Timer.delay(function():Void {
            callback(args);
        }, 0);
        #end
    }

    /**
     * @{inheritDoc}
     */
    override public function trigger(event:String, ?args:Null<Args>):Feedback
    {
        if (this.hasEvent(event)) {
            #if (cpp || java || neko)
            this.mutex.acquire();
            #end
            var callbacks:Array<Callback> = this.eventMap.get(event).copy();
            #if (cpp || java || neko)
            this.mutex.release();
            #end

            var promise:Promise = new Promise(callbacks.length);
            var callback:Callback;
            for (callback in callbacks) {
                this.runCallback(function(args:Null<Args>):Void {
                    callback(args);
                    promise.resolve();
                }, args);
            }

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
