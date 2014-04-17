class Runner
{
    public static function main():Void
    {
        var r = new haxe.unit.TestRunner();

        r.add( new TestCascade() );
        r.add( new TestFuture() );
        r.add( new TestPromise() );

        r.run();
    }
}
