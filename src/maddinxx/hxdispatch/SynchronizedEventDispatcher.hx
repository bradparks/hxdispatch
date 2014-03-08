package maddinxx.hxdispatch;

#if cpp
    import cpp.vm.Mutex;
#elseif neko
    import neko.vm.Mutex;
#else
    #error "SynchronizedEventDispatcher not supported on target platform due to missing Mutex support. Please use EventDispatcher instead."
#end
import maddinxx.hxdispatch.EventArgs;
import maddinxx.hxdispatch.EventCallback;
import maddinxx.hxdispatch.EventDispatcher;

/**
 * The synchronized Event dispatcher adds thread safety to the normal implementation.
 */
class SynchronizedEventDispatcher extends EventDispatcher
{
    private var mutex:Mutex;

    /**
     * @{inheritDoc}
     */
    public function new():Void
    {
        super();
        this.mutex = new Mutex();
    }

    /**
     * @{inheritDoc}
     */
    override public function get_events():Array<String>
    {
        var events:Array<String> = new Array<String>();
        this.mutex.acquire();
        var keys:Iterator<String> = this.eventMap.keys();
        this.mutex.release();
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
        this.mutex.acquire();
        var has:Bool = this.eventMap.exists(event);
        this.mutex.release();
        return has;
    }

    /**
     * @{inheritDoc}
     */
    override public function listenEvent(event:String, callback:EventCallback):Bool
    {
        if (this.hasEvent(event)) {
            this.mutex.acquire();
            var callbacks:Array<EventCallback> = this.eventMap.get(event);
            if (!Lambda.exists(callbacks, function(fn:EventCallback):Bool {
                return Reflect.compareMethods(callback, fn);
            })) {
                callbacks.push(callback);
                this.mutex.release();
                this.trigger("_eventListened", { event: event, callback: callback });

                return true;
            }
        }

        return false;
    }

    /**
     * @{inheritDoc}
     */
    override public function registerEvent(event:String, ?callback:EventCallback):Bool
    {
        if (!this.hasEvent(event)) {
            var callbacks:Array<EventCallback> = new Array<EventCallback>();
            if (callback != null) {
                callbacks.push(callback);
            }
            this.mutex.acquire();
            this.eventMap.set(event, callbacks);
            this.mutex.release();
            this.trigger("_eventRegistered", { event: event, callback: callback });

            return true;
        }

        return false;
    }

    /**
     * @{inheritDoc}
     */
    override public function trigger(event:String, ?args:EventArgs):Bool
    {
        if (this.hasEvent(event)) {
            this.mutex.acquire();
            var callbacks:Array<EventCallback> = this.eventMap.get(event).copy();
            this.mutex.release();
            var callback:EventCallback;
            for (callback in callbacks) {
                callback(args);
            }

            if (event != "_eventTriggered") {
                this.trigger("_eventTriggered", { event: event, args: args });
            }

            return true;
        }

        return false;
    }

    /**
     * @{inheritDoc}
     */
    override public function unlistenEvent(event:String, callback:EventCallback):Bool
    {
        if (this.hasEvent(event)) {
            this.mutex.acquire();
            var removed:Bool = this.eventMap.get(event).remove(callback);
            this.mutex.release();
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
            this.mutex.acquire();
            this.eventMap.remove(event);
            this.mutex.release();

            this.trigger("_eventUnregistered", { event: event });

            return true;
        }

        return false;
    }
}
