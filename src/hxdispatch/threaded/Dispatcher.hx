package hxdispatch.threaded;

#if cpp
    import cpp.vm.Mutex;
#elseif java
    import java.vm.Mutex;
#elseif neko
    import neko.vm.Mutex;
#elseif !js
    #error "Threaded Dispatcher is not supported on target platform due to the lack of Mutex feature."
#end
import hxdispatch.Callback;
import hxdispatch.Dispatcher.Feedback;
import hxdispatch.Dispatcher.Status;
#if !js
    import hxdispatch.threaded.Promise;
#else
    import hxdispatch.Promise;
#end
import hxdispatch.utils.Nil;

/**
 * Threads-safe Dispatcher implementation preventing register, listen and trigger
 * faults when multiple threads access the same data.
 *
 * @{inherit}
 */
class Dispatcher<T> extends hxdispatch.Dispatcher<T>
{
    #if !js
    private var mutex:Mutex;
    #end

    /**
     * @{inherit}
     */
    public function new():Void
    {
        super();
        #if !js
        this.mutex = new Mutex();
        #end
    }

    /**
     * @{inherit}
     */
    override private function get_events():Array<Event>
    {
        var events:Array<Event> = new Array<Event>();
        #if !js
        this.mutex.acquire();
        #end
        for (key in this.map.keys()) {
            events.push(key);
        }
        #if !js
        this.mutex.release();
        #end

        return events;
    }

    /**
     * @{inherit}
     */
    override public function hasEvent(event:Event):Bool
    {
        #if !js
        this.mutex.acquire();
        #end
        var exists:Bool = this.map.exists(event);
        #if !js
        this.mutex.release();
        #end

        return exists;
    }

    /**
     * @{inherit}
     */
    override public function listenEvent(event:Event, callback:Callback<Null<T>>):Bool
    {
        var listening:Bool = false;
        #if !js
        this.mutex.acquire();
        #end
        if (this.map.exists(event) && callback != null) {
            var callbacks:Array<Callback<Null<T>>> = this.map.get(event);
            if (!Lambda.exists(callbacks, function(fn:Callback<Null<T>>):Bool {
                return Reflect.compareMethods(callback, fn);
            })) {
                callbacks.push(callback);
                listening = true;
            }
        }
        #if !js
        this.mutex.release();
        #end
        this.trigger("_eventListened");

        return listening;
    }

    /**
     * @{inherit}
     */
    override public function registerEvent(event:Event, ?callback:Callback<Null<T>>):Bool
    {
        var registered:Bool = false;
        #if !js
        this.mutex.acquire();
        #end
        if (!this.map.exists(event)) {
            var callbacks:Array<Callback<Null<T>>> = new Array<Callback<Null<T>>>();
            if (callback != null) {
                callbacks.push(callback);
            }
            this.map.set(event, callbacks);
            registered = true;
        }
        #if !js
        this.mutex.release();
        #end
        this.trigger("_eventRegistered");

        return registered;
    }

    /**
     * @{inherit}
     */
    override public function trigger(event:Event, ?args:Null<T>):Feedback
    {
        if (this.hasEvent(event)) {
            #if !js
            this.mutex.acquire();
            #end
            var callbacks:Array<Callback<Null<T>>> = this.map.get(event).copy();
            #if !js
            this.mutex.release();
            #end
            var promise:Promise<Nil> = new Promise<Nil>(callbacks.length);
            var callback:Callback<Null<T>>;
            for (callback in callbacks) {
                this.executeCallback(function(args:Null<T>):Void {
                    callback(args);
                    promise.resolve(null);
                }, args);
            }

            if (event != "_eventTriggered") {
                this.trigger("_eventTriggered");
            }

            return { status: Status.TRIGGERED, promise: promise };
        }

        return { status: Status.NO_SUCH_EVENT };
    }

    /**
     * @{inherit}
     */
    override public function unlistenEvent(event:Event, callback:Callback<Null<T>>):Bool
    {
        var unlistened:Bool = false;
        #if !js
        this.mutex.acquire();
        #end
        if (this.map.exists(event) && callback != null) {
            if (this.map.get(event).remove(callback)) {
                unlistened = true;
            }
        }
        #if !js
        this.mutex.release();
        #end
        this.trigger("_eventUnlistened");

        return unlistened;
    }

    /**
     * @{inherit}
     */
    override public function unregisterEvent(event:Event):Bool
    {
        var unregistered:Bool = false;
        #if !js
        this.mutex.acquire();
        #end
        if (this.map.exists(event)) {
            this.map.remove(event);
            unregistered = true;
        }
        #if !js
        this.mutex.release();
        #end
        this.trigger("_eventUnregistered");

        return unregistered;
    }
}


/**
 * @{inherit}
 */
typedef Feedback =
{> hxdispatch.Feedback,
    @:optional public var promise:Promise<Nil>;
};
