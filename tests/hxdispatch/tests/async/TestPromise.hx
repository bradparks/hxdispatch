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


    /**
     * Overriden since async Promise will not wait until the Callback sets the executed Bool to true.
     *
     * @{inherit}
     */
    override public function testDoneWhenRejected():Void
    {
        var input:Int = 5;
        var executed:Bool = false;
        this.promise.done(function(arg:Int):Void {
            assertEquals(input, arg);
            executed = true;
        });
        this.promise.reject(input);
        untyped this.promise.await();
        assertTrue(executed);
    }

    /**
     * Overriden since async Promise will not wait until the Callback sets the executed Bool to true.
     *
     * @{inherit}
     */
    override public function testDoneWhenResolved():Void
    {
        var input:Int = 5;
        var executed:Bool = false;
        this.promise.done(function(arg:Int):Void {
            assertEquals(input, arg);
            executed = true;
        });
        this.promise.resolve(input);
        untyped this.promise.await();
        assertTrue(executed);
    }

    /**
     * Overriden since async Promise will not wait until the Callback sets the executed Bool to true.
     *
     * @{inherit}
     */
    override public function testExecuteCallbacksCatchesException():Void
    {
        var input:Int = 5;
        var executed:Bool = false;
        this.promise.resolved(function(arg:Int):Void {
            throw "Exception in Callback";
        });
        this.promise.done(function(arg:Int):Void {
            assertEquals(input, arg);
            executed = true;
        });
        this.promise.resolve(input);
        untyped this.promise.await();
        assertTrue(executed);
    }

    /**
     * Checks that when multiple resolves are required, Callback functions
     * are not executed before all required resolves have been called.
     */
    override public function testMultipleResolves():Void
    {
        var executed:Bool = false;
        this.promise = new hxdispatch.async.Promise<Int>(new hxdispatch.async.ThreadExecutor(), 2);
        this.promise.done(function(arg:Int):Void {
            executed = true;
        });

        this.promise.resolve(0);
        assertFalse(executed);

        this.promise.resolve(0);
        untyped this.promise.await();
        assertTrue(executed);
    }

    /**
     * Overriden since async Promise will not wait until the Callback sets the executed Bool to true.
     *
     * @{inherit}
     */
    override public function testRejected():Void
    {
        var input:Int = 5;
        var executed:Bool = false;
        this.promise.rejected(function(arg:Int):Void {
            assertEquals(input, arg);
            executed = true;
        });
        this.promise.reject(5);
        untyped this.promise.await();
        assertTrue(executed);
    }

    /**
     * Overriden since async Promise will not wait until the Callback sets the executed Bool to true.
     *
     * @{inherit}
     */
    override public function testRejectedWhenResolved():Void
    {
        var executed:Bool = false;
        this.promise.rejected(function(arg:Int):Void {
            executed = true;
        });
        this.promise.resolve(0);
        untyped this.promise.await();
        assertFalse(executed);
    }

    /**
     * Overriden since async Promise will not wait until the Callback sets the executed Bool to true.
     *
     * @{inherit}
     */
    override public function testResolved():Void
    {
        var input:Int = 5;
        var executed:Bool = false;
        this.promise.resolved(function(arg:Int):Void {
            assertEquals(input, arg);
            executed = true;
        });
        this.promise.resolve(input);
        untyped this.promise.await();
        assertTrue(executed);
    }

    /**
     * Overriden since async Promise will not wait until the Callback sets the executed Bool to true.
     *
     * @{inherit}
     */
    override public function testResolvedWhenRejected():Void
    {
        var executed:Bool = false;
        this.promise.resolved(function(arg:Int):Void {
            executed = true;
        });
        this.promise.reject(0);
        untyped this.promise.await();
        assertFalse(executed);
    }
}
