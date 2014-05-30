package hxdispatch.tests.concurrent;

import hxdispatch.concurrent.Future;

/**
 * TestSuite for the hxdispatch.concurrent.Future class.
 */
class TestFuture extends hxdispatch.tests.TestFuture
{
    /**
     * @{inherit}
     */
    override public function setup():Void
    {
        this.future = new Future<Int>();
    }
}
