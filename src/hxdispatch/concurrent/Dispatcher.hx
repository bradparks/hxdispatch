package hxdispatch.concurrent;

#if !js
    import hxstd.vm.IMutex;
    import hxstd.vm.Mutex;
#end
import hxdispatch.Callback;
import hxdispatch.Dispatcher.Feedback;
import hxdispatch.Dispatcher.Status;
import hxdispatch.Event;
import hxstd.ds.LinkedList;

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
     * @var hxstd.vm.IMutex
     */
    #if !js private var mutex:IMutex; #end


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
        listening = super.attach(event, callback);
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
        unlistened = super.dettach(event, callback);
        #if !js this.mutex.release(); #end

        return unlistened;
    }

    /**
     * @{inherit}
     */
    override public function hasEvent(event:Event):Bool
    {
        #if !js this.mutex.acquire(); #end
        var ret:Bool = super.hasEvent(event);
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
        registered = super.register(event);
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
            var callbacks = this.map.get(event);
            this.executeCallbacks(Lambda.array(callbacks), arg); // make sure we iterate over a copy
            #if !js this.mutex.release(); #end

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
        unregistered = super.unregister(event);
        #if !js this.mutex.release(); #end

        return unregistered;
    }
}
