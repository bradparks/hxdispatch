package hxdispatch.tests.concurrent;

/**
 * TestSuite for the hxdispatch.concurrent.Dispatcher class.
 *
 * TODO: concurrent specific tests
 */
class TestDispatcher extends hxdispatch.tests.TestDispatcher
{
    /**
     * @{inherit}
     */
    override public function setup():Void
    {
        this.dispatcher = new hxdispatch.concurrent.Dispatcher<Int>();
    }
}
