package maddinxx.hxdispatch;

#if cpp
import cpp.vm.Deque;
import cpp.vm.Mutex;
import cpp.vm.Thread;
#elseif java
import java.vm.Deque;
import java.vm.Mutex;
import java.vm.Thread;
#elseif js
import haxe.Timer;
#elseif neko
import neko.vm.Deque;
import neko.vm.Mutex;
import neko.vm.Thread;
#else
#error "PooledDispatcher not supported on target platform due to missing Deque/Mutex/Thread support. Please use ThreadedDispatcher instead."
#end
import maddinxx.hxdispatch.Args;
import maddinxx.hxdispatch.Callback;
import maddinxx.hxdispatch.Feedback;
import maddinxx.hxdispatch.Feedback.Status;
import maddinxx.hxdispatch.Promise;
import maddinxx.hxdispatch.ThreadedDispatcher;

/**
 * The pooled dispatcher extends the thread dispatcher and is thus real async as well.
 * Instead of one thread per callback, this implementation has a fixed worker pool however.
 */
class PooledDispatcher extends ThreadedDispatcher
{
    private var executors:Deque<Thread>;
    private var queue:Deque<Job>;

    /**
     * Constructor to initialize a new Dispatcher.
     *
     * @param Int workers the number of workers to spawn
     */
    public function new(?workers:Int = 1):Void
    {
        super();

        this.executors = new Deque<Thread>();
        this.queue     = new Deque<Job>();
        for (i in 0...workers) {
            this.executors.add(Thread.create(function():Void {
                while (true) {
                    var job:Job = this.queue.pop(true);
                    job.callback(job.args);
                }
            }));
        }
    }

    /**
     * @{inheritDoc}
     */
    override private function runCallback(callback:Callback, args:Args):Void
    {
        this.queue.add({ callback: callback, args: args });
    }
}


private typedef Job =
{
    var callback:Callback;
    var args:Args;
};
