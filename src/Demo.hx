#if cpp
    import cpp.vm.Thread;
#elseif neko
    import neko.vm.Thread;
#end
import hxdispatch.Event;
import hxdispatch.Event.Args;
import hxdispatch.threaded.Dispatcher;
import hxdispatch.threaded.Dispatcher.Feedback;
import hxdispatch.threaded.Future;
import hxdispatch.threaded.Promise;

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

        trace(future.get(true));
        Sys.sleep(0.5); // wait for other thread getting

        var promise:Promise<String> = new Promise<String>();
        promise.then(function(name:String):Void {
            trace("My name is " + name);
        });
        Thread.create(function():Void {
            promise.then(function(name:String):Void {
                trace("His name is " + name);
            });
            trace("Thread awaiting");
            promise.await();
            trace("Thread got promise too");
        });
        Thread.create(function():Void {
            promise.resolve("Michel");
        });

        promise.await();
        Sys.sleep(0.5); // wait for other thread awaiting

        var dispatcher:Dispatcher<Args> = new Dispatcher<Args>();
        dispatcher.registerEvent("click", function(name:Args):Void {
            trace("Event's value is " + name);
        });
        Thread.create(function():Void {
            var feedback:Feedback = dispatcher.trigger("click", { name: "Max" });
        });

        Sys.sleep(0.5); // wait for other thread triggering

        return 0;
    }
}
