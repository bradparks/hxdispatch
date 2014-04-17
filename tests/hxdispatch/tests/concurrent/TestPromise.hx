package hxdispatch.tests.concurrent;

/**
 * TestSuite for the hxdispatch.concurrent.Promise class.
 *
 * TODO: static when() method
 * TODO: concurrent specific tests
 */
class TestPromise extends hxdispatch.tests.TestPromise
{
    /**
     * @{inherit}
     */
    override public function setup():Void
    {
        this.promise = new hxdispatch.concurrent.Promise<Int>();
    }
}
