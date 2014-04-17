package hxdispatch.tests.concurrent;

/**
 * TODO: add JS to concurrent build list (but not compatible with Promise)
 */
class Runner
{
    public static function main():Void
    {
        var r = new haxe.unit.TestRunner();

        r.add( new hxdispatch.tests.concurrent.TestCascade() );
        r.add( new hxdispatch.tests.concurrent.TestDispatcher() );
        r.add( new hxdispatch.tests.concurrent.TestPromise() );

        r.run();
    }
}
