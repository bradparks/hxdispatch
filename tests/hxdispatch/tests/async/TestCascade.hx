package hxdispatch.tests.async;

/**
 * TestSuite for the hxdispatch.async.Cascade class.
 *
 * TODO: async specific tests
 */
class TestCascade extends hxdispatch.tests.concurrent.TestCascade
{
    /**
     * @{inherit}
     */
    override public function setup():Void
    {
        this.cascade = new hxdispatch.async.Cascade<Int>(new hxdispatch.async.ThreadExecutor());
    }
}
