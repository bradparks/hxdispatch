package hxdispatch.tests.async;

/**
 * TestSuite for the hxdispatch.async.Dispatcher class.
 *
 * TODO: async specific tests
 * TODO: mock ThreadExecutor
 */
class TestDispatcher extends hxdispatch.tests.concurrent.TestDispatcher
{
    /**
     * @{inherit}
     */
    override public function setup():Void
    {
        this.dispatcher = new hxdispatch.async.Dispatcher<Int>(new hxstd.threading.ThreadExecutor());
    }


    /**
     * Overriden since trigger() is async and we have to make sure the Callbacks are executed for this test.
     *
     * @{inherit}
     */
    override public function testAttach():Void
    {
        var input:Int = 5;
        var executed:Bool = false;
        this.dispatcher.register("event");
        assertTrue(this.dispatcher.attach("event", function(arg:Int):Void {
            assertEquals(input, arg);
            executed = true;
        }));
        var feedback:hxdispatch.async.Dispatcher.Feedback = untyped this.dispatcher.trigger("event", input);
        feedback.promise.await();
        assertTrue(executed);
    }

    /**
     * Overriden since async Dispatcher returns another Status code.
     *
     * @{inherit}
     */
    override public function testTriggerExistingEvent():Void
    {
        this.dispatcher.register("event");
        assertEquals(this.dispatcher.trigger("event", 0).status, hxdispatch.Dispatcher.Status.TRIGGERED);
    }
}
