import hxdispatch.threaded.Future;
import hxdispatch.Promise;
#if cpp
    import cpp.vm.Thread;
#elseif neko
    import neko.vm.Thread;
#end

class Demo
{
    public static function main():Int
    {
        var future:Future<Int> = new Future<Int>();
        Thread.create(function():Void {
            trace(future.get(true));
        });
        Thread.create(function():Void {
            future.reject();
        });

        var promise:Promise<String> = new Promise<String>();
        promise.then(function(name:String):Void {
            trace("My name is " + name);
        });
        promise.resolve("Michel");

        Sys.sleep(2);

        return 0;
    }
}
