package hxdispatch.tests;

import haxe.unit.TestRunner;
import mcover.coverage.MCoverage;
import mcover.coverage.CoverageLogger;

/**
 * TestSuite runner for classes in hxdispatch package.
 */
class Runner
{
    public static function main():Void
    {
        var r = new TestRunner();

        r.add( new hxdispatch.tests.TestCascade() );
        r.add( new hxdispatch.tests.TestDispatcher() );
        r.add( new hxdispatch.tests.TestFuture() );
        r.add( new hxdispatch.tests.TestPromise() );

        #if (cpp || java || js || neko)
            r.add( new hxdispatch.tests.concurrent.TestCascade() );
            r.add( new hxdispatch.tests.concurrent.TestDispatcher() );
            #if !js
                r.add( new hxdispatch.tests.concurrent.TestFuture() );
            #end
            r.add( new hxdispatch.tests.concurrent.TestPromise() );

            #if !js
                r.add( new hxdispatch.tests.async.TestCascade() );
                r.add( new hxdispatch.tests.async.TestDispatcher() );
                r.add( new hxdispatch.tests.async.TestPromise() );
            #end
        #end

        // #if neko
        //     var logger:CoverageLogger = MCoverage.getLogger();
        //     logger.report();
        // #end

        var success:Bool = r.run();
        #if sys
            Sys.exit(success ? 0 : 1);
        #end
    }
}
