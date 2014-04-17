package hxdispatch.async;

import hxdispatch.Cascade.Tier;
import hxdispatch.concurrent.Future;

/**
 *
 */
class Cascade<T> extends hxdispatch.concurrent.Cascade<T>
{
    /**
     * Stores the Executor used to process the Tiers.
     *
     * @var hxdispatch.async.Executor<hxdispatch.Cascade.Tier<T>>
     */
    private var executor:Executor<Tier<T>>;


    /**
     * @param hxdispatch.async.Executor<hxdispatch.Cascade.Tier<T>> the Tier Executor to use
     *
     * @{inherit}
     */
    public function new(executor:Executor<Tier<T>>):Void
    {
        super();
        this.executor = executor;
    }

    /**
     * @{inherit}
     */
    public function plunge(arg:T):Future<T>
    {
        this.mutex.acquire();
        var tiers:Array<Tier<T>> = Lambda.array(this.tiers).concat(Lambda.array(this.finals));
        this.mutex.release();

        var future:Future<T> = new Future<T>();
        this.executor.execute(function(arg:T):Void {
            var tier:Tier<T>;
            for (tier in tiers) {
                arg = tier(arg);
            }
            future.resolve(arg);
        }, arg);

        return future;
    }
}
