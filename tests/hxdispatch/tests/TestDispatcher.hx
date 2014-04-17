package hxdispatch.tests;

/**
 * TestSuite for the hxdispatch.Dispatcher class.
 */
class TestDispatcher extends haxe.unit.TestCase
{
    /**
     * Stores the Dispatcher on which the tests are run.
     *
     * @var hxdispatch.Dispatcher<Int>
     */
    private var dispatcher:hxdispatch.Dispatcher<Int>;


    /**
     * @{inherit}
     */
    override public function setup():Void
    {
        this.dispatcher = new hxdispatch.Dispatcher<Int>();
    }

    /**
     *@{inherit}
     */
    override public function tearDown():Void
    {
        this.dispatcher = null;
    }


    /**
     * Checks the hasEvent() method.
     *
     * Attn: This test depends on the register() method - make sure tests for this class pass
     * before looking for errors in the hasEvent() method.
     */
    public function testHasEvent():Void
    {
        var event:hxdispatch.Event = "event";
        assertFalse(this.dispatcher.hasEvent(event));
        this.dispatcher.register(event);
        assertTrue(this.dispatcher.hasEvent(event));
    }
}
