package hxdispatch;

import Map;
import haxe.ds.IntMap;
import hxdispatch.Callback;
import hxdispatch.Event;
import hxstd.util.Reflector;

/**
 * The Dispatcher class can be used to have a central Event dispatching service/instance.
 *
 * Objects can register new events, listen for triggers and much more.
 *
 * Since this is a non-threaded version all callbacks are executed in sync and the benefit of
 * using the class is not as large as when used in multi-threaded/async environments.
 *
 * @generic E the type of the events one can subscribe to
 * @generic A the type of arguments the callbacks accept
 */
class Dispatcher<E:Event, A>
{
    /**
     * Stores a map of events and their subscribers.
     *
     * @var IMap<E, Array<Callback<A>>>
     */
    private var map:IMap<E, Array<Callback<A>>>;


    /**
     * Constructor to initialize a new Dispatcher.
     */
    public function new():Void
    {
        this.map = cast new IntMap<Array<Callback<A>>>();
    }

    /**
     * Executes the callback with the provided argument.
     *
     * @param Callback<A> callback the callback to execute
     * @param A           arg      the argument to pass to the callback
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
     * Checks if the event is already registered.
     *
     * @param E event the event to search for
     *
     * @return Bool
     */
    public function hasEvent(event:E):Bool
    {
        return this.map.exists(this.toTypeConstrain(event));
    }

    /**
     * Adds the callback to the event's subscriber list.
     *
     * @param E           event    the event to subscribe to
     * @param Callback<A> callback the callback to add
     *
     * @return Bool true if added to the list
     */
    public function subscribe(event:E, callback:Callback<A>):Bool
    {
        if (this.hasEvent(event) && callback != null) {
            var callbacks:Array<Callback<A>> = this.map.get(this.toTypeConstrain(event));
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
     * Registers the new event.
     *
     * @param E event the event to register
     *
     * @return Bool true if registered successfully
     */
    public function register(event:E):Bool
    {
        if (!this.hasEvent(event)) {
            var callbacks:Array<Callback<A>> = new Array<Callback<A>>();
            this.map.set(this.toTypeConstrain(event), callbacks);

            return true;
        }

        return false;
    }

    /**
     * Returns the Event converted to the type constrain.
     *
     * This method was introduced to allow subclasses to override
     * one method only rather than having to change code in all classes
     * communicating with the map.
     *
     * @param Event event the event to get the constrain for/of
     *
     * @return E
     */
    private function toTypeConstrain(event:Event):E
    {
        return cast Reflector.hashCode(event);
    }

    /**
     * Triggers the event (with the optional event arguments).
     *
     * @param E event the event to trigger
     * @param A arg   the optional argument to pass to the callbacks
     *
     * @return Feedback
     */
    public function trigger(event:E, ?arg:A = null):Feedback
    {
        if (this.hasEvent(event)) {
            var callbacks:Array<Callback<A>> = this.map.get(this.toTypeConstrain(event)).copy();
            var callback:Callback<A>;
            for (callback in callbacks) {
                this.executeCallback(callback, arg);
            }

            return { status: Status.OK };
        }

        return { status: Status.NO_SUCH_EVENT };
    }

    /**
     * Removes the callback from the event's subscriber list.
     *
     * @param E           event    the event to remove the callback from
     * @param Callback<A> callback the callback to remove
     *
     * @return Bool true if removed successfully
     */
    public function unsubscribe(event:E, callback:Callback<A>):Bool
    {
        if (this.hasEvent(event) && callback != null) {
            if (this.map.get(this.toTypeConstrain(event)).remove(callback)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Unregisters the event from the Dispatcher.
     *
     * @param E event the event to unregister
     *
     * @return Bool true if unregistered successfully
     */
    public function unregister(event:E):Bool
    {
        if (this.hasEvent(event)) {
            this.map.remove(this.toTypeConstrain(event));

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
