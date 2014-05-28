package hxdispatch.concurrent;

#if !js
    import hxstd.ds.SynchronizedList;
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
     * @{inherit}
     */
    public function new():Void
    {
        super();
        #if !js this.tiers = new SynchronizedList<Tier<T>>(this.tiers); #end
    }
}
