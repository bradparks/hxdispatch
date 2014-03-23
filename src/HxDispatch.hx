import hxdispatch.threaded.Promise;
import neko.vm.Thread;

class HxDispatch
{
    public static function main():Void
    {
        var p = new Promise<Int>();
        Thread.create(function():Void {
            p.then(function(nr:Int):Void {
                trace(nr);
            });
            p.await();
            trace("Thread finished");
        });

        p.then(function(nr:Int):Void {
            trace(nr*2);
        });

        Thread.create(function():Void {
            p.resolve(5);
        });

        p.await();
        trace("finished");
    }
}
