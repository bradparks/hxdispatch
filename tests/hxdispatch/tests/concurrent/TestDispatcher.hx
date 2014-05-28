package hxdispatch.tests.concurrent;

import hxdispatch.concurrent.Dispatcher;

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
        this.dispatcher = new Dispatcher<Int>();
    }
}
