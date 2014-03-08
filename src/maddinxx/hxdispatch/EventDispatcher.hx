package maddinxx.hxdispatch;

import Map;
import maddinxx.hxdispatch.EventArgs;
import maddinxx.hxdispatch.EventCallback;

/**
 * A simple Event dispatcher for the Haxe language
 * and its C++/NekoVM targets.
 */
class EventDispatcher
{
    public var events(get, never):Array<String>;
    private var eventMap:Map<String, Array<EventCallback>>;

    /**
     * Constructor to initialize a new EventDispatcher.
     */
    public function new():Void
    {
        this.eventMap = new Map<String, Array<EventCallback>>();

        // internal events
        this.eventMap.set("_eventRegistered",   new Array<EventCallback>());
        this.eventMap.set("_eventUnregistered", new Array<EventCallback>());
        this.eventMap.set("_eventTriggered",    new Array<EventCallback>());
        this.eventMap.set("_eventListened",     new Array<EventCallback>());
        this.eventMap.set("_eventUnlistened",   new Array<EventCallback>());
    }

    /**
     * Returns an Array of all registered events.
     *
     * @return Array<String> the registered events
     */
    public function get_events():Array<String>
    {
        var keys:Array<String> = new Array<String>();
        for (key in this.eventMap.keys()) {
            keys.push(key);
        }
        return keys;
    }

    /**
     * Checks if the event is already registered.
     *
     * @param String event the event's name
     *
     * @return Bool
     */
    private function hasEvent(event:String):Bool
    {
        return this.eventMap.exists(event);
    }

    /**
     * Adds the callback function as a listener to the named event.
     *
     * @param String        event    the event's name
     * @param EventCallback callback the callback to add
     *
     * @return Bool true if added to the list
     */
    public function listenEvent(event:String, callback:EventCallback):Bool
    {
        if (this.hasEvent(event)) {
            var callbacks:Array<EventCallback> = this.eventMap.get(event);
            if (!Lambda.exists(callbacks, function(fn:EventCallback):Bool {
                return Reflect.compareMethods(callback, fn);
            })) {
                callbacks.push(callback);
                this.trigger("_eventListened", { event: event, callback: callback });

                return true;
            }
        }

        return false;
    }

    /**
     * @see EventDispatcher.listenEvent()
     */
    public function onEvent(event:String, callback:EventCallback):Bool
    {
        return this.listenEvent(event, callback);
    }

    /**
     * Registers a new event with an optional callback.
     *
     * @param String        event    the event's name
     * @param EventCallback callback the initial callback to set
     *
     * @return Bool true if registered successfully
     */
    public function registerEvent(event:String, ?callback:EventCallback):Bool
    {
        if (!this.hasEvent(event)) {
            var callbacks:Array<EventCallback> = new Array<EventCallback>();
            if (callback != null) {
                callbacks.push(callback);
            }
            this.eventMap.set(event, callbacks);
            this.trigger("_eventRegistered", { event: event, callback: callback });

            return true;
        }

        return false;
    }

    /**
     * Triggers the named event with the optional arguments.
     *
     * @param String        event the event's name
     * @param Null<Dynamic> args  the optional arguments to pass to the callbacks
     *
     * @return Bool true if triggered
     */
    public function trigger(event:String, ?args:EventArgs):Bool
    {
        if (this.hasEvent(event)) {
            var callbacks:Array<EventCallback> = this.eventMap.get(event);
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
     * Unlistens/removes the callback from the event listeners.
     *
     * @param String        event    the event's name
     * @param EventCallback callback the callback to remove
     *
     * @return Bool true if removed successfully
     */
    public function unlistenEvent(event:String, callback:EventCallback):Bool
    {
        if (this.hasEvent(event)) {
            if (this.eventMap.get(event).remove(callback)) {
                this.trigger("_eventUnlistened", { event: event, callback: callback });
                return true;
            }
        }

        return false;
    }

    /**
     * Unregisters an event by completely removing it.
     *
     * @param String event the event's name
     *
     * @return Bool true if removed successfully
     */
    public function unregisterEvent(event:String):Bool
    {
        if (this.hasEvent(event)) {
            this.eventMap.remove(event);
            this.trigger("_eventUnregistered", { event: event });

            return true;
        }

        return false;
    }
}
