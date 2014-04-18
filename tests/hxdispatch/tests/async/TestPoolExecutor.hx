package hxdispatch.tests.async;

/**
 * TestSuite for the hxdispatch.async.PoolExecutor class.
 *
 * TODO: Report bug: Java Threads block exiting main thread
 */
class TestPoolExecutor extends haxe.unit.TestCase
{
    /**
     * Stores the Executor on which the tests are run.
     *
     * @var hxdispatch.async.PoolExecutor<Int>
     */
    private var executor:hxdispatch.async.PoolExecutor<Int>;


    /**
     * @{inherit}
     */
    override public function setup():Void
    {
        this.executor = new hxdispatch.async.PoolExecutor<Int>();
    }

    /**
     *@{inherit}
     */
    override public function tearDown():Void
    {
        this.executor = null;
    }


    /**
     * Checks that the execute() method really handles the Callback.
     */
    public function testExecute():Void
    {
        var value:Int = 0;
        this.executor.execute(function(arg:Int):Void {
            value = arg;
        }, 5);
        Sys.sleep(0.1); // "wait" for Executor
        assertEquals(value, 5);
    }

    /**
     * Checks that the execute() method catches exceptions thrown in Callbacks.
     *
     * If we would not catch them, our Executor would stop working after the first exception.
     */
    public function testExecuteCatchesException():Void
    {
        var value:Int = 0;
        this.executor.execute(function(arg:Int):Void {
            throw "Exception in Callback";
        }, 0);
        this.executor.execute(function(arg:Int):Void {
            value = arg;
        }, 5);
        Sys.sleep(0.2); // "wait" for Executor
        assertEquals(value, 5);
    }
}
