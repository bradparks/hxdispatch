package hxdispatch.tests.concurrent;

/**
 * TestSuite for the hxdispatch.concurrent.Future class.
 *
 * TODO: concurrent specific tests
 */
class TestFuture extends hxdispatch.tests.TestFuture
{
    /**
     * @{inherit}
     */
    override public function setup():Void
    {
        this.future = new hxdispatch.concurrent.Future<Int>();
    }


    /**
     * Overriden to prevent blocking.
     *
     * @{inherit}
     */
    override public function testGetThrowsWorkflowException():Void
    {
        try {
            this.future.get(false);
            assertFalse(true);
        } catch (ex:hxdispatch.WorkflowException) {
            assertTrue(true);
        }
    }
}
