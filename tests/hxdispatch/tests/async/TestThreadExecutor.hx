package hxdispatch.tests.async;

/**
 * TestSuite for the hxdispatch.async.ThreadExecutor class.
 */
class TestThreadExecutor extends haxe.unit.TestCase
{
    /**
     * Stores the Executor on which the tests are run.
     *
     * @var hxdispatch.async.ThreadExecutor<Int>
     */
    private var executor:hxdispatch.async.ThreadExecutor<Int>;


    /**
     * @{inherit}
     */
    override public function setup():Void
    {
        this.executor = new hxdispatch.async.ThreadExecutor<Int>();
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
}
