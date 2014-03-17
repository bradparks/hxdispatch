package hxdispatch.threaded;

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
 * Each callback is executed by one of the defined callback executors.
 *
 * It's recommended to use this implementation for trigger intensive applications.
 *
 * @{inherit}
 */
class PoolDispatcher<T> extends hxdispatch.threaded.Dispatcher<T>
{
    private var executors:Vector<Executor>;
    private var jobs:Deque<Job>;

    /**
     * @param Int pool the number of callback executors
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
     * Initializes the pool of Event callback executors.
     */
    private function initialize():Void
    {
        for (i in 0...this.executors.length) {
            this.executors.set(i, Thread.create(function():Void {
                var job:Job;
                while (true) {
                    job = this.jobs.pop(true);
                    job.fn(job.args);
                }
            }));
        }
    }

    /**
     * @{inherit}
     */
    override private function executeCallback(callback:Callback<T>, args:Null<T>):Void
    {
        this.jobs.add({ fn: callback, args: args });
    }
}


/**
 *
 */
private typedef Executor = Thread;

/**
 * A Job combines a Callback with the arguments it should be called with.
 */
private typedef Job =
{
    public var fn:Callback<Dynamic>;
    public var args:Args;
};
