package hxdispatch.tests.concurrent;

/**
 * TestSuite for the hxdispatch.concurrent.Promise class.
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
