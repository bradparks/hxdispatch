#if cpp
    import cpp.vm.Thread;
#elseif java
    import java.vm.Thread;
#elseif neko
    import neko.vm.Thread;
#else
    #error "Not supported on target plattform."
#end

class Dispatcher
{
    public static function main():Void
    {
        var d = new hxdispatch.concurrent.PoolDispatcher<String>(2);
        d.register("event");

        d.attach("event", function(arg:String):Void {
            trace(arg);
        });
        Thread.create(function():Void {
            d.attach("event", function(arg:String):Void {
                Sys.sleep(1);
                trace(arg);
            });
        });

        Thread.create(function():Void {
            var f:hxdispatch.concurrent.Dispatcher.Feedback = d.trigger("event", "Event fired");
            f.promise.await();
            trace("Callbacks executed by Pool Executors");
        });

        d.trigger("event", "Non blocking trigger");
        trace("Getting here without block");

        Sys.sleep(2); // demo only, wait for Threads since main Thread has nothing blocking
    }
}
