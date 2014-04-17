package hxdispatch.tests.async;

/**
 *
 */
class Runner
{
    public static function main():Void
    {
        var r = new haxe.unit.TestRunner();

        r.add( new hxdispatch.tests.async.TestCascade() );
        r.add( new hxdispatch.tests.async.TestDispatcher() );
        r.add( new hxdispatch.tests.async.TestPromise() );

        r.run();
    }
}
