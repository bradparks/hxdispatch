package hxdispatch;

import Map;
import hxdispatch.Callback;
import hxdispatch.Event;
import hxdispatch.Event.Args;

/**
 * The Dispatcher class can be used to have a central Event dispatching service/instance.
 *
 * Objects can register new Events, listen for triggers and much more.
 *
 * Since this is a non-threaded version all Callbacks are executed in sync and the benefit of
 * using the class is not as large as when used in multi-threaded/async environments.
 *
 * @generic A:Args  the type of arguments the Callbacks accept
 */
class Dispatcher<A:Args>
{
    /**
     * Stores a map of Events and their Callbacks.
     *
     * @var Map<Event, Array<hxdispatch.Callback<A>>>
     */
    private var map:Map<Event, Array<Callback<A>>>;


    /**
     * Constructor to initialize a new Dispatcher.
     */
    public function new():Void
    {
        this.map = new Map<Event, Array<Callback<A>>>();
    }

    /**
     * Attachs the Callback to the Event.
     *
     * @param Event                  event    the Event to attach to
     * @param hxdispatch.Callback<A> callback the Callback to add
     *
     * @return Bool true if attached
     */
    public function attach(event:Event, callback:Callback<A>):Bool
    {
        if (this.hasEvent(event) && callback != null) {
            var callbacks:Array<Callback<A>> = this.map.get(event);
            if (!Lambda.exists(callbacks, function(fn:Callback<A>):Bool {
                return Reflect.compareMethods(callback, fn);
            })) {
                callbacks.push(callback);

                return true;
            }
        }

        return false;
    }

    /**
     * Dettachs the Callback from the Event.
     *
     * @param Event                  event    the Event to dettach from
     * @param hxdispatch.Callback<A> callback the Callback to remove
     *
     * @return Bool true if dettached successfully
     */
    public function dettach(event:Event, callback:Callback<A>):Bool
    {
        if (this.hasEvent(event) && callback != null) {
            if (this.map.get(event).remove(callback)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Executes the Callback with the provided argument.
     *
     * @param hxdispatch.Callback<A> callback the Callback to execute
     * @param A                      arg      the argument to pass to the Callback
     */
    private function executeCallback(callback:Callback<A>, arg:A):Void
    {
        try {
            callback(arg);
        } catch (ex:Dynamic) {
            // CallbackException
        }
    }

    /**
     * Checks if the Event is already registered.
     *
     * @param Event event the Event to search for
     *
     * @return Bool
     */
    public function hasEvent(event:Event):Bool
    {
        return this.map.exists(event);
    }

    /**
     * Registers the new Event.
     *
     * @param Event event the Event to register
     *
     * @return Bool true if registered successfully
     */
    public function register(event:Event):Bool
    {
        if (!this.hasEvent(event)) {
            var callbacks:Array<Callback<A>> = new Array<Callback<A>>();
            this.map.set(event, callbacks);

            return true;
        }

        return false;
    }

    /**
     * Triggers the event (with the optional event argument).
     *
     * @param Event event the Event to trigger
     * @param A     arg   the optional argument to pass to the Callbacks
     *
     * @return hxdispatch.Dispatcher.Feedback
     */
    public function trigger(event:Event, ?arg:A = null):Feedback
    {
        if (this.hasEvent(event)) {
            var callbacks:Array<Callback<A>> = this.map.get(event).copy();
            var callback:Callback<A>;
            for (callback in callbacks) {
                this.executeCallback(callback, arg);
            }

            return { status: Status.OK };
        }

        return { status: Status.NO_SUCH_EVENT };
    }

    /**
     * Unregisters the Event from the Dispatcher.
     *
     * @param Event event the Event to unregister
     *
     * @return Bool true if unregistered successfully
     */
    public function unregister(event:Event):Bool
    {
        if (this.hasEvent(event)) {
            this.map.remove(event);

            return true;
        }

        return false;
    }
}


/**
 * Type returned by a trigger() call summarizing the execution
 * progress of the registered callbacks for the given Event.
 */
typedef Feedback =
{
    public var status:Status;
}


/**
 * Status marker used in Feedback typedef to tell the caller
 * if the trigger has been successful (and been executed),
 * the execution of the callbacks has been dispatched to another
 * service or the Event does not exist.
 */
enum Status
{
    OK;
    NO_SUCH_EVENT;
    NOT_DEFINED;
    TRIGGERED;
}
