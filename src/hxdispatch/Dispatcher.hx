package hxdispatch;

import Map;
import hxdispatch.Callback;
import hxdispatch.Event;
import hxdispatch.Event.Args;
import hxdispatch.Promise;

/**
 *
 */
@:generic
class Dispatcher<T>
{
    private var map:Map<Event, Array<Callback<Null<T>>>>;
    public var events(get, never):Array<Event>;

    /**
     *
     */
    public function new():Void
    {
        this.map = new Map<Event, Array<Callback<Null<T>>>>();

        // internal events
        this.map.set("_eventRegistered",   new Array<Callback<Null<T>>>());
        this.map.set("_eventUnregistered", new Array<Callback<Null<T>>>());
        this.map.set("_eventTriggered",    new Array<Callback<Null<T>>>());
        this.map.set("_eventListened",     new Array<Callback<Null<T>>>());
        this.map.set("_eventUnlistened",   new Array<Callback<Null<T>>>());
    }

    /**
     * Returns an Array of all registered events.
     *
     * @return Array<Event> the registered events
     */
    public function get_events():Array<Event>
    {
        var events:Array<Event> = new Array<Event>();
        for (key in this.map.keys()) {
            events.push(key);
        }
        return events;
    }

    /**
     * Checks if the event is already registered.
     *
     * @param Event event the event's name
     *
     * @return Bool
     */
    public function hasEvent(event:Event):Bool
    {
        return this.map.exists(event);
    }

    /**
     * Adds the callback function as a listener to the named event.
     *
     * @param Event             event    the event's name
     * @param Callback<Null<T>> callback the callback to add
     *
     * @return Bool true if added to the list
     */
    public function listenEvent(event:Event, callback:Callback<Null<T>>):Bool
    {
        if (this.hasEvent(event) && callback != null) {
            var callbacks:Array<Callback<Null<T>>> = this.map.get(event);
            if (!Lambda.exists(callbacks, function(fn:Callback<Null<T>>):Bool {
                return Reflect.compareMethods(callback, fn);
            })) {
                callbacks.push(callback);
                // this.trigger("_eventListened", { event: event, callback: callback });
                this.trigger("_eventListened");

                return true;
            }
        }

        return false;
    }

    /**
     * @see EventDispatcher.listenEvent()
     */
    public inline function onEvent(event:Event, callback:Callback<Null<T>>):Bool
    {
        return this.listenEvent(event, callback);
    }

    /**
     * Registers a new event with an optional callback.
     *
     * @param   Event             event    the event's name
     * @param   Callback<Null<T>> callback the initial callback to set
     *
     * @return Bool true if registered successfully
     */
    public function registerEvent(event:Event, ?callback:Callback<Null<T>>):Bool
    {
        if (!this.hasEvent(event)) {
            var callbacks:Array<Callback<Null<T>>> = new Array<Callback<Null<T>>>();
            if (callback != null) {
                callbacks.push(callback);
            }
            this.map.set(event, callbacks);
            // this.trigger("_eventRegistered", { event: event, callback: callback });
            this.trigger("_eventRegistered");

            return true;
        }

        return false;
    }

    /**
     * Triggers the named event with the optional arguments.
     *
     * @param Event   event the event's name
     * @param Null<T> args  the optional arguments to pass to the callbacks
     *
     * @return Feedback
     */
    public function trigger(event:Event, ?args:Null<T>):Feedback
    {
        if (this.hasEvent(event)) {
            if (event != "_eventTriggered") {
                // this.trigger("_eventTriggered", { event: event, args: args });
                this.trigger("_eventTriggered");
            }

            var callbacks:Array<Callback<Null<T>>> = this.map.get(event);
            var callback:Callback<Null<T>>;
            for (callback in callbacks) {
                callback(args);
            }

            return { status: Status.OK }; // true
        }

        return { status: Status.NO_SUCH_EVENT };
    }

    /**
     * Unlistens/removes the callback from the event listeners.
     *
     * @param Event             event    the event's name
     * @param Callback<Null<T>> callback the callback to remove
     *
     * @return Bool true if removed successfully
     */
    public function unlistenEvent(event:Event, callback:Callback<Null<T>>):Bool
    {
        if (this.hasEvent(event) && callback != null) {
            if (this.map.get(event).remove(callback)) {
                // this.trigger("_eventUnlistened", { event: event, callback: callback });
                this.trigger("_eventUnlistened");
                return true;
            }
        }

        return false;
    }

    /**
     * Unregisters an event by completely removing it.
     *
     * @param Event event the event's name
     *
     * @return Bool true if removed successfully
     */
    public function unregisterEvent(event:Event):Bool
    {
        if (this.hasEvent(event)) {
            // this.trigger("_eventUnregistered", { event: event });
            this.trigger("_eventUnregistered");
            this.map.remove(event);

            return true;
        }

        return false;
    }
}


/**
 *
 */
typedef Feedback =
{
    public var status:Status;
}


/**
 *
 */
enum Status
{
    OK;
    NO_SUCH_EVENT;
    TRIGGERED;
}
