package hxdispatch.tests.async;

/**
 * TestSuite for the hxdispatch.async.Dispatcher class.
 *
 * TODO: async specific tests
 */
class TestDispatcher extends hxdispatch.tests.concurrent.TestDispatcher
{
    /**
     * @{inherit}
     */
    override public function setup():Void
    {
        this.dispatcher = new hxdispatch.async.Dispatcher<Int>(new hxdispatch.async.ThreadExecutor());
    }
}
