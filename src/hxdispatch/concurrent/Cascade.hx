package hxdispatch.concurrent;

#if (cpp || cs || flash || java || neko)
    import hxstd.vm.Mutex;
#elseif !js
    #error "Concurrent Cascade is not supported on target platform due to the lack of Mutex feature."
#end
import hxdispatch.Cascade.Tier;

/**
 * Threads-safe Cascade implementation.
 *
 * @{inherit}
 */
class Cascade<T> extends hxdispatch.Cascade<T>
{
    /**
     * Stores the Mutex used to synchronize access to the Tier lists.
     *
     * @var Mutex
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
    override public function descend(arg:T):T
    {
        #if !js this.mutex.acquire(); #end
        var tiers:Array<Tier<T>> = Lambda.array(this.tiers);
        #if !js this.mutex.release(); #end

        var tier:Tier<T>;
        for (tier in tiers) {
            arg = tier(arg);
        }

        return arg;
    }

    /**
     * @{inherit}
     */
    override public function initially(callback:Tier<T>):Cascade<T>
    {
        #if !js this.mutex.acquire(); #end
        this.tiers.push(callback);
        #if !js this.mutex.release(); #end

        return this;
    }

    /**
     * @{inherit}
     */
    override public function then(callback:Tier<T>):Cascade<T>
    {
        #if !js this.mutex.acquire(); #end
        this.tiers.add(callback);
        #if !js this.mutex.release(); #end

        return this;
    }
}
