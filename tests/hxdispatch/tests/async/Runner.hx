package hxdispatch.tests.async;

/**
 * TestSuite runner for classes in hxdispatch.async package.
 */
class Runner
{
    public static function main():Void
    {
        var r = new haxe.unit.TestRunner();

        r.add( new hxdispatch.tests.async.TestCascade() );
        r.add( new hxdispatch.tests.async.TestDispatcher() );
        r.add( new hxdispatch.tests.async.TestPoolExecutor() );
        r.add( new hxdispatch.tests.async.TestPromise() );
        r.add( new hxdispatch.tests.async.TestThreadExecutor() );

        var success:Bool = r.run();

        #if sys
            Sys.exit(success ? 0 : 1);
        #end
    }
}
