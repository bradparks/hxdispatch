package hxdispatch.tests;

/**
 * TestSuite runner for classes in hxdispatch package.
 */
class Runner
{
    public static function main():Void
    {
        var r = new haxe.unit.TestRunner();

        r.add( new hxdispatch.tests.TestCascade() );
        r.add( new hxdispatch.tests.TestDispatcher() );
        r.add( new hxdispatch.tests.TestFuture() );
        r.add( new hxdispatch.tests.TestPromise() );

        var success:Bool = r.run();

        #if sys
            Sys.exit(success ? 0 : 1);
        #end
    }
}
