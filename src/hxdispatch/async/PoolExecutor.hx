package hxdispatch.async;

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
    #error "Pooled Executor is not supported on target platform due to the lack of Deque/Thread feature."
#end
import haxe.ds.Vector;
import hxdispatch.Callback;
import hxdispatch.async.Executor;

/**
 *
 */
class PoolExecutor<T> implements Executor<T>
{
    /**
     * Stores the executor threads that will handle the jobs.
     *
     * @var Vector<Thread>
     */
    private var executors:Vector<Thread>;

    /**
     * Stores the jobs/callbacks the executors need to process.
     *
     * @var Deque<Job<T>>
     */
    private var jobs:Deque<Job<T>>;


    /**
     * Constructor to initialize a new PoolExecutor.
     *
     * @param Int pool the number of threads to put into the pool
     */
    public function new(?pool:Int = 1):Void
    {
        this.executors = new Vector<Thread>(pool);
        this.jobs      = new Deque<Job<T>>();
        this.initialize();
    }

    /**
     * Initializes the executing threads.
     */
    private function initialize():Void
    {
        for (i in 0...this.executors.length) {
            this.executors.set(i, Thread.create(function():Void {
                var job:Job<T>;
                while (true) {
                    job = this.jobs.pop(true);
                    try {
                        job.fn(job.arg);
                    } catch (ex:Dynamic) {}
                }
            }));
        }
    }

    /**
     * @{inherit}
     */
    public function execute(callback:Callback<T>, arg:T):Void
    {
        this.jobs.add({ fn: callback, arg: arg });
    }
}


/**
 * Typedef representing a Job for the execution threads.
 */
private typedef Job<T> =
{
    var fn:T->Void;
    var arg:T;
}
