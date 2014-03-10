#if cpp
    import cpp.vm.Thread;
#elseif java
    import java.vm.Thread;
#elseif neko
    import neko.vm.Thread;
#end
import hxdispatch.Event;
import hxdispatch.Event.Args;
import hxdispatch.threaded.Dispatcher;
import hxdispatch.threaded.Dispatcher.Feedback;
import hxdispatch.threaded.Future;
import hxdispatch.threaded.Promise;
import hxdispatch.threaded.PoolDispatcher;
import hxdispatch.threaded.ThreadDispatcher;

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

        var dispatcher:PoolDispatcher<Args> = new PoolDispatcher<Args>();
        dispatcher.registerEvent("click", function(name:Args):Void {
            Sys.sleep(1);
            trace("Event's value is " + name);
        });
        var feedback:Feedback = dispatcher.trigger("click", { name: "Max" });
        Thread.create(function():Void {
            trace("Before promise resolved");
            feedback.promise.await();
            trace("Promise resolved");
        });
        Thread.create(function():Void {
            trace("Before promise resolved");
            feedback.promise.await();
            trace("Promise resolved");
        });

        for (i in 0...30) {
            Sys.sleep(0.1);
            trace(i);
        }

        return 0;
    }
}
