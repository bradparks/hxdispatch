package hxdispatch.tests.async;

/**
 * TestSuite for the hxdispatch.async.Promise class.
 *
 * TODO: static when() method
 * TODO: async specific tests
 */
class TestPromise extends hxdispatch.tests.concurrent.TestPromise
{
    /**
     * @{inherit}
     */
    override public function setup():Void
    {
        this.promise = new hxdispatch.async.Promise<Int>(new hxdispatch.async.ThreadExecutor());
    }
}
