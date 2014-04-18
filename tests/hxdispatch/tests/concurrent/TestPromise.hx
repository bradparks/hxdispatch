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

    /**
     * @{inherit}
     */
    override private function getPromise(?resolves:Int = 1):Promise<Dynamic>
    {
        return new hxdispatch.concurrent.Promise<Dynamic>(resolves);
    }
}
