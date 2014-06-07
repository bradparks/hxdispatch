package hxdispatch.tests.concurrent;

import hxdispatch.concurrent.Cascade;

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
        this.cascade = new Cascade<Int>();
    }
}
