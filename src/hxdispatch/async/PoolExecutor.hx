package hxdispatch.async;

#if cpp
    import cpp.vm.Deque;
#elseif java
    import java.vm.Deque;
#elseif neko
    import neko.vm.Deque;
#else
    #error "Pooled Executor is not supported on target platform due to the lack of Deque/Thread feature."
#end
import haxe.ds.Vector;
import hxdispatch.Callback;
import hxdispatch.async.Executor;
import hxstd.vm.Thread;

/**
 * The PoolExecutor Executor implementation uses a fixed-size pool of
 * worker/execution threads to process the callbacks passed by execute().
 *
 * This implementation is recommended for applications that "trigger" the
 * execute() method quite often.
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
     * @var Deque<hxdispatch.async.PoolExecutor.Job<T>>
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
