package maddinxx.hxdispatch;

#if cpp
import cpp.vm.Mutex;
#elseif java
import java.vm.Mutex;
#elseif neko
import neko.vm.Mutex;
#elseif !js
#error "SyncedDispatcher not supported on target platform due to missing Mutex support. Please use Dispatcher instead."
#end
import maddinxx.hxdispatch.Args;
import maddinxx.hxdispatch.Callback;
import maddinxx.hxdispatch.Dispatcher;
import maddinxx.hxdispatch.Feedback;
import maddinxx.hxdispatch.Feedback.Status;

/**
 * The synchronized Event dispatcher adds thread safety to the normal implementation.
 */
class SyncedDispatcher extends Dispatcher
{
    #if (cpp || java || neko)
    private var mutex:Mutex;
    #end

    /**
     * @{inheritDoc}
     */
    public function new():Void
    {
        super();

        #if (cpp || java || neko)
        this.mutex = new Mutex();
        #end
    }

    /**
     * @{inheritDoc}
     */
    override public function get_events():Array<String>
    {
        var events:Array<String> = new Array<String>();
        #if (cpp || java || neko)
        this.mutex.acquire();
        #end
        var keys:Iterator<String> = this.eventMap.keys();
        #if (cpp || java || neko)
        this.mutex.release();
        #end
        for (key in keys) {
            events.push(key);
        }
        return events;
    }

    /**
     * @{inheritDoc}
     */
    override private function hasEvent(event:String):Bool
    {
        #if (cpp || java || neko)
        this.mutex.acquire();
        #end
        var has:Bool = this.eventMap.exists(event);
        #if (cpp || java || neko)
        this.mutex.release();
        #end
        return has;
    }

    /**
     * @{inheritDoc}
     */
    override public function listenEvent(event:String, callback:Callback):Bool
    {
        if (this.hasEvent(event) && callback != null) {
            #if (cpp || java || neko)
            this.mutex.acquire();
            #end
            var callbacks:Array<Callback> = this.eventMap.get(event);
            if (!Lambda.exists(callbacks, function(fn:Callback):Bool {
                return Reflect.compareMethods(callback, fn);
            })) {
                callbacks.push(callback);
                #if (cpp || java || neko)
                this.mutex.release();
                #end
                this.trigger("_eventListened", { event: event, callback: callback });

                return true;
            }
        }

        return false;
    }

    /**
     * @{inheritDoc}
     */
    override public function registerEvent(event:String, ?callback:Callback):Bool
    {
        if (!this.hasEvent(event)) {
            var callbacks:Array<Callback> = new Array<Callback>();
            if (callback != null) {
                callbacks.push(callback);
            }
            #if (cpp || java || neko)
            this.mutex.acquire();
            #end
            this.eventMap.set(event, callbacks);
            #if (cpp || java || neko)
            this.mutex.release();
            #end
            this.trigger("_eventRegistered", { event: event, callback: callback });

            return true;
        }

        return false;
    }

    /**
     * Runs the given callback with the provided arguments.
     *
     * This step has been out-sourced for easier extending.
     *
     * @param Callback callback the callback to execute
     * @param Args     args     the arguments to pass to the callback
     */
    private function runCallback(callback:Callback, args:Args):Void
    {
        callback(args);
    }

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
            var callback:Callback;
            for (callback in callbacks) {
                this.runCallback(callback, args);
            }

            if (event != "_eventTriggered") {
                this.trigger("_eventTriggered", { event: event, args: args });
            }

            return { status: Status.OK }; // true
        }

        return { status: Status.NO_SUCH_EVENT };
    }

    /**
     * @{inheritDoc}
     */
    override public function unlistenEvent(event:String, callback:Callback):Bool
    {
        if (this.hasEvent(event) && callback != null) {
            #if (cpp || java || neko)
            this.mutex.acquire();
            #end
            var removed:Bool = this.eventMap.get(event).remove(callback);
            #if (cpp || java || neko)
            this.mutex.release();
            #end
            if (removed) {
                this.trigger("_eventUnlistened", { event: event, callback: callback });
                return true;
            }
        }

        return false;
    }

    /**
     * @{inheritDoc}
     */
    override public function unregisterEvent(event:String):Bool
    {
        if (this.hasEvent(event)) {
            #if (cpp || java || neko)
            this.mutex.acquire();
            #end
            this.eventMap.remove(event);
            #if (cpp || java || neko)
            this.mutex.release();
            #end

            this.trigger("_eventUnregistered", { event: event });

            return true;
        }

        return false;
    }
}
