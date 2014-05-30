package hxdispatch.tests.concurrent;

import hxdispatch.concurrent.Promise;

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
        this.promise = new Promise<Int>();
    }

    /**
     * @{inherit}
     */
    override private function getPromise(?resolves:Int = 1):hxdispatch.concurrent.Promise<Dynamic>
    {
        return new Promise<Dynamic>(resolves);
    }
}
