package hxdispatch.concurrent;

#if (cpp || cs || flash || java || neko)
    import hxstd.vm.Mutex;
#elseif !js
    #error "Concurrent Dispatcher is not supported on target platform due to the lack of Mutex feature."
#end
import hxdispatch.Callback;
import hxdispatch.Dispatcher.Feedback;
import hxdispatch.Dispatcher.Status;
import hxdispatch.Event;

/**
 * Threads-safe Dispatcher implementation preventing register, listen and trigger
 * faults when multiple threads access the same data.
 *
 * @{inherit}
 */
class Dispatcher<T> extends hxdispatch.Dispatcher<T>
{
    /**
     * Stores the Mutex used to synchronize access.
     *
     * @var hxstd.vm.Mutex
     */
    #if !js private var mutex:Mutex; #end


    /**
     * @{inherit}
     */
    public function new():Void
    {
        super();
        #if !js this.mutex = new Mutex(); #end
    }

    /**
     * @{inherit}
     */
    override public function attach(event:Event, callback:Callback<T>):Bool
    {
        var listening:Bool = false;
        #if !js this.mutex.acquire(); #end
        if (this.map.exists(event) && callback != null) {
            var callbacks:Array<Callback<T>> = this.map.get(event);
            if (!Lambda.exists(callbacks, function(fn:Callback<T>):Bool {
                return Reflect.compareMethods(callback, fn);
            })) {
                callbacks.push(callback);
                listening = true;
            }
        }
        #if !js this.mutex.release(); #end

        return listening;
    }

    /**
     * @{inherit}
     */
    override public function dettach(event:Event, callback:Callback<T>):Bool
    {
        var unlistened:Bool = false;
        #if !js this.mutex.acquire(); #end
        if (this.map.exists(event) && callback != null) {
            if (this.map.get(event).remove(callback)) {
                unlistened = true;
            }
        }
        #if !js this.mutex.release(); #end

        return unlistened;
    }

    /**
     * @{inherit}
     */
    override public function hasEvent(event:Event):Bool
    {
        #if !js this.mutex.acquire(); #end
        var ret:Bool = this.map.exists(event);
        #if !js this.mutex.release(); #end

        return ret;
    }

    /**
     * @{inherit}
     */
    override public function register(event:Event):Bool
    {
        var registered:Bool = false;
        #if !js this.mutex.acquire(); #end
        if (!this.map.exists(event)) {
            var callbacks:Array<Callback<T>> = new Array<Callback<T>>();
            this.map.set(event, callbacks);
            registered = true;
        }
        #if !js this.mutex.release(); #end

        return registered;
    }

    /**
     * @{inherit}
     */
    override public function trigger(event:Event, arg:T):Feedback
    {
        if (this.hasEvent(event)) {
            #if !js this.mutex.acquire(); #end
            var callbacks:Array<Callback<T>> = this.map.get(event).copy();
            #if !js this.mutex.release(); #end
            var callback:Callback<T>;
            for (callback in callbacks) {
                this.executeCallback(callback, arg);
            }

            return { status: Status.OK };
        }

        return { status: Status.NO_SUCH_EVENT };
    }

    /**
     * @{inherit}
     */
    override public function unregister(event:Event):Bool
    {
        var unregistered:Bool = false;
        #if !js this.mutex.acquire(); #end
        if (this.map.exists(event)) {
            this.map.remove(event);
            unregistered = true;
        }
        #if !js this.mutex.release(); #end

        return unregistered;
    }
}
