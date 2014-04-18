package hxdispatch.tests.concurrent;

/**
 * TestSuite for the hxdispatch.concurrent.Cascade class.
 */
class TestCascade extends hxdispatch.tests.TestCascade
{
    /**
     * @{inherit}
     */
    override public function setup():Void
    {
        this.cascade = new hxdispatch.concurrent.Cascade<Int>();
    }
}
