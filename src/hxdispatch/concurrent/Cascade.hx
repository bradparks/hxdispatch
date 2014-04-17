package hxdispatch.concurrent;

#if cpp
    import cpp.vm.Mutex;
#elseif java
    import java.vm.Mutex;
#elseif neko
    import neko.vm.Mutex;
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
    private var Mutex:Mutex;


    /**
     * @{inherit}
     */
    public function new():Void
    {
        super();
        this.mutex = new Mutex();
    }

    /**
     * @{inherit}
     */
    override public function descend(arg:T):T
    {
        this.mutex.acquire();
        var tiers:Array<Tier<T>> = Lambda.array(this.tiers);
        this.mutex.release();

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
        this.mutex.acquire();
        this.tiers.push(callback);
        this.mutex.release();

        return this;
    }

    /**
     * @{inherit}
     */
    override public function then(callback:Tier<T>):Cascade<T>
    {
        this.mutex.acquire();
        this.tiers.add(callback);
        this.mutex.release();

        return this;
    }
}
