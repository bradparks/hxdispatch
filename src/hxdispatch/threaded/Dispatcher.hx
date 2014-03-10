package hxdispatch.threaded;

#if cpp
    import cpp.vm.Mutex;
#elseif java
    import java.vm.Mutex;
#elseif neko
    import neko.vm.Mutex;
#else
    #error "Threaded Dispatcher is not supported on target platform due to the lack of Mutex feature."
#end
import hxdispatch.Callback;
import hxdispatch.Dispatcher.Feedback;
import hxdispatch.Dispatcher.Status;
import hxdispatch.threaded.Promise;
import hxdispatch.utils.Nil;

/**
 *
 */
@:generic
class Dispatcher<T> extends hxdispatch.Dispatcher<T>
{
    private var mutex:Mutex;

    /**
     *
     */
    public function new():Void
    {
        super();
        this.mutex = new Mutex();
    }

    /**
     * @{inherit}
     */
    override public function get_events():Array<Event>
    {
        var events:Array<Event> = new Array<Event>();
        this.mutex.acquire();
        for (key in this.map.keys()) {
            events.push(key);
        }
        this.mutex.release();

        return events;
    }

    /**
     * @{inherit}
     */
    override public function hasEvent(event:Event):Bool
    {
        this.mutex.acquire();
        var exists:Bool = this.map.exists(event);
        this.mutex.release();

        return exists;
    }

    /**
     * @{inherit}
     */
    override public function listenEvent(event:Event, callback:Callback<Null<T>>):Bool
    {
        var listening:Bool = false;
        this.mutex.acquire();
        if (this.map.exists(event) && callback != null) {
            var callbacks:Array<Callback<Null<T>>> = this.map.get(event);
            if (!Lambda.exists(callbacks, function(fn:Callback<Null<T>>):Bool {
                return Reflect.compareMethods(callback, fn);
            })) {
                callbacks.push(callback);
                listening = true;
            }
        }
        this.mutex.release();
        this.trigger("_eventListened");

        return listening;
    }

    /**
     * @{inherit}
     */
    override public function registerEvent(event:Event, ?callback:Callback<Null<T>>):Bool
    {
        var registered:Bool = false;
        this.mutex.acquire();
        if (!this.map.exists(event)) {
            var callbacks:Array<Callback<Null<T>>> = new Array<Callback<Null<T>>>();
            if (callback != null) {
                callbacks.push(callback);
            }
            this.map.set(event, callbacks);
            registered = true;
        }
        this.mutex.release();
        this.trigger("_eventRegistered");

        return registered;
    }

    /**
     * @{inherit}
     */
    override public function trigger(event:Event, ?args:Null<T>):Feedback
    {
        if (this.hasEvent(event)) {
            this.mutex.acquire();
            var callbacks:Array<Callback<Null<T>>> = this.map.get(event).copy();
            this.mutex.release();
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
        this.mutex.acquire();
        if (this.map.exists(event) && callback != null) {
            if (this.map.get(event).remove(callback)) {
                unlistened = true;
            }
        }
        this.mutex.release();
        this.trigger("_eventUnlistened");

        return unlistened;
    }

    /**
     * @{inherit}
     */
    override public function unregisterEvent(event:Event):Bool
    {
        var unregistered:Bool = false;
        this.mutex.acquire();
        if (this.map.exists(event)) {
            this.map.remove(event);
            unregistered = true;
        }
        this.mutex.release();
        this.trigger("_eventUnregistered");

        return unregistered;
    }
}


/**
 *
 */
typedef Feedback =
{> hxdispatch.Feedback,
    @:optional public var promise:Promise<Nil>;
};
