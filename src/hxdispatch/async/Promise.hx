package hxdispatch.async;

#if (cpp || cs || java || neko)
    import hxstd.vm.MultiLock;
    import hxstd.vm.Mutex;
#elseif !js
    #error "Async Promise is not supported on target platform due to the lack of Lock/Mutex feature."
#end
import hxstd.threading.Executor;

/**
 *
 * TODO: bug on line 153 (upstream?)
 */
class Promise<T> extends hxdispatch.concurrent.Promise<T>
{
    /**
     * Stores either the Callbacks are being executed or not.
     *
     * @var Bool
     */
    private var executing:Bool;

    /**
     * Stores the Executor used to process Callbacks.
     *
     * @var hxstd.threading.Executor<T>
     */
    private var executor:Executor<T>;

    /**
     * Stores the Lock used to block await() callers.
     *
     * @var hxstd.vm.MultiLock
     */
    #if !js private var lock:MultiLock; #end

    /**
     * Stores the number of waiters (having called await).
     *
     * @var Int
     */
    private var waiters:Int;


    /**
     * @param hxstd.threading.Executor<T> the Callback Executor to use
     *
     * @{inherit}
     */
    public function new(executor:Executor<T>, resolves:Int = 1):Void
    {
        super(resolves);

        this.executing     = false;
        this.executor      = executor;
        #if !js this.lock  = new MultiLock(); #end
        this.waiters       = 0;
    }

    /**
     * Blocks the calling Thread until the Promise has been marked as done
     * and Callbacks have been processed.
     */
    #if !js
        public function await():Void
        {
            this.mutex.acquire();
            if (!this.isDone() || this.isExecuting()) {
                ++this.waiters;
                this.mutex.release();
                this.lock.wait();
                --this.waiters;
            } else {
                this.mutex.release();
            }
        }
    #end

    /**
     * Checks if the Promise is still executing its Callbacks.
     *
     * @return Bool
     */
    public function isExecuting():Bool
    {
        #if !js this.mutex.acquire(); #end
        var ret:Bool = this.executing;
        #if !js this.mutex.release(); #end

        return ret;
    }

    /**
     * @{inherit}
     */
    override private function executeCallbacks(callbacks:Iterable<Callback<T>>, arg:T):Void
    {
        var count:Int;
        if ((count = Lambda.count(callbacks)) == 0) {
            #if !js this.unlock(); #end
        } else {
            #if !js this.mutex.acquire(); #end
            this.executing = true;
            #if !js this.mutex.release();
            var mutex:Mutex = new Mutex(); #end

            var callback:Callback<T>;
            for (callback in callbacks) {
                this.executor.execute(function(arg:T):Void {
                    #if HXDISPATCH_DEBUG
                        callback(arg);
                    #else
                        try {
                            callback(arg);
                        } catch (ex:Dynamic) {}
                    #end

                    #if !js mutex.acquire();
                    if (--count == 0) {
                        this.mutex.acquire();
                        this.executing = false;
                        this.unlock();
                        this.mutex.release();
                    }
                    mutex.release(); #end
                }, arg);
            }
        }
    }

    /**
     * Unlocks the Lock that is used to block waiters in await() method.
     */
    #if !js
        private function unlock():Void
        {
            this.mutex.acquire();
            while (this.waiters != 0) {
                this.lock.release();
            }
            this.mutex.release();
        }
    #end

    /**
     * @{inherit}
     */
    public static function when<T>(promises:Array<Promise<T>>, ?executor:Executor<T>):Promise<T>
    {
        if (executor == null) {
            executor = new hxstd.threading.Executor.Sequential<T>();
        }

        var promise:Promise<T> = new Promise<T>(executor, 1);
        var done:Bool;
        for (p in promises) {
            #if !js p.mutex.acquire(); #end
            done = p.state != State.NONE;
            if (!done) {
                ++promise.resolves;
                p.done(function(arg:T):Void {
                    if (p.isRejected()) {
                        promise.reject(arg);
                    } else {
                        promise.resolve(arg);
                    }
                });
            }
            #if !js p.mutex.release(); #end
        }
        --promise.resolves;

        if (promise.resolves == 0) {
            throw new WorkflowException("Promises have already been rejected or resolved");
        }

        return promise;
    }
}
