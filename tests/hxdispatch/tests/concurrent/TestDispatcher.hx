package hxdispatch.tests.concurrent;

/**
 * TestSuite for the hxdispatch.concurrent.Dispatcher class.
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
