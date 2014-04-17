package hxdispatch.tests.concurrent;

/**
 *
 */
class Runner
{
    public static function main():Void
    {
        var r = new haxe.unit.TestRunner();

        r.add( new hxdispatch.tests.concurrent.TestCascade() );
        r.add( new hxdispatch.tests.concurrent.TestDispatcher() );
        r.add( new hxdispatch.tests.concurrent.TestFuture() );
        r.add( new hxdispatch.tests.concurrent.TestPromise() );

        r.run();
    }
}
