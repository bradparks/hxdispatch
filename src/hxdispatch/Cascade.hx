package hxdispatch;

import hxstd.ds.IList;
import hxstd.ds.LinkedList;

/**
 * The Cascade (waterfall) class can be used to execute functions
 * (so called Tiers) in order, passing the return value of each Tier
 * to the next one.
 *
 * @generic T the type of argument/return values the Tiers will pass
 */
class Cascade<T>
{
    /**
     * Stores the Tiers.
     *
     * @var hxstd.ds.IList<hxdispatch.Cascade.Tier<T>>
     */
    private var tiers:IList<Tier<T>>;


    /**
     * Constructor to initialize a new Cascade.
     */
    public function new():Void
    {
        this.tiers = new LinkedList<Tier<T>>();
    }

    /**
     * Descends all the Tiers and returns the final return value.
     *
     * @param T arg the argument to pass to the first Tier
     *
     * @return T the return value of the last Tier
     */
    public function descend(arg:T):T
    {
        var tier:Tier<T>;
        for (tier in Lambda.array(this.tiers)) { // make sure we iterate over a copy
            arg = tier(arg);
        }

        return arg;
    }

    /**
     * Adds the Tier to the end of the Cascade.
     *
     * @param hxdispatch.Cascade.Tier<T> callback the Tier to add
     *
     * @return hxdispatch.Cascade<T>
     */
    public function then(callback:Tier<T>):Cascade<T>
    {
        this.tiers.add(callback);
        return this;
    }
}


/**
 * Each step of a Cascade is represented by a Tier.
 * That Tier gets the return value from the previous Tier
 * and must return a value, so following Tiers get an input
 * argument as well.
 */
typedef Tier<T> = T->T;
