package hxdispatch.concurrent;

#if cpp
    import cpp.vm.Deque;
    import cpp.vm.Thread;
#elseif java
    import java.vm.Deque;
    import java.vm.Thread;
#elseif neko
    import neko.vm.Deque;
    import neko.vm.Thread;
#else
    #error "PoolDispatcher is not supported on target platform due to the lack of Deque/Thread feature."
#end
import haxe.ds.Vector;
import hxdispatch.Callback;
import hxdispatch.Event.Args;

/**
 * The PoolDispatcher implementation is a thread-safe, asynchronous implementation
 * of a Dispatcher.
 *
 * Each Callback is executed by one of the defined Callback Executors.
 *
 * It's recommended to use this implementation for trigger intensive applications.
 *
 * @{inherit}
 */
class PoolDispatcher<A:Args> extends hxdispatch.concurrent.Dispatcher<A>
{
    /**
     * Stores the pool of Executors.
     *
     * @var haxe.ds.Vector<hxdispatch.concurrent.PoolDispatcher.Executor>
     */
    private var executors:Vector<Executor>;

    /**
     * Stores the Jobs/Callbacks to be executed.
     *
     * @var Deque<hxdispatch.concurrent.PoolDispatcher.Job>
     */
    private var jobs:Deque<Job>;


    /**
     * @param Int pool the number of Callback Executors
     *
     * @{inherit}
     */
    public function new(?pool:Int = 1):Void
    {
        super();

        this.executors = new Vector<Executor>(pool);
        this.jobs      = new Deque<Job>();
        this.initialize();
    }

    /**
     * Initializes the pool of Event Callback Executors.
     */
    private function initialize():Void
    {
        for (i in 0...this.executors.length) {
            this.executors.set(i, Thread.create(function():Void {
                var job:Job;
                while (true) {
                    job = this.jobs.pop(true);
                    try {
                        job.fn(job.arg);
                    } catch (ex:Dynamic) {
                        // CallbackException
                    }
                }
            }));
        }
    }

    /**
     * @{inherit}
     */
    override private function executeCallback(callback:Callback<A>, arg:Null<A>):Void
    {
        this.jobs.add({ fn: callback, arg: arg });
    }
}


/**
 * An Executor is a standalone Thread that handles Callback Jobs.
 */
private typedef Executor = Thread;


/**
 * A Job combines a Callback with the Argument(s) it should be called with.
 */
private typedef Job =
{
    public var fn:Callback<Dynamic>;
    public var arg:Args;
};
