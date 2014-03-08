import maddinxx.hxdispatch.EventArgs;
import maddinxx.hxdispatch.EventCallback;
import maddinxx.hxdispatch.EventDispatcher;
import maddinxx.hxdispatch.SynchronizedEventDispatcher;
import maddinxx.hxdispatch.ThreadedEventDispatcher;

typedef Dispatcher = ThreadedEventDispatcher;

class Demo
{
    public static function main():Int
    {
        var callback:EventCallback = function(args:EventArgs):Void {
            trace("\t\tPosition not defined...");
            Sys.sleep(1);
            trace("6. Callback thread executed");
        };

        var dispatcher = new Dispatcher();
        dispatcher.onEvent("_eventTriggered", function(args:EventArgs):Void {
            trace("\t\tInternal event triggered");
        });

        dispatcher.registerEvent("demo", callback);
        trace("1. registered event");

        dispatcher.onEvent("demo", function(args:EventArgs):Void {
            trace("\t\tPosition not defined...");
            Sys.sleep(0.2);
            trace("5. Callback thread executed");
        });
        trace("2. Added another callback");

        trace("3. Triggering events");
        dispatcher.trigger("demo", { name: "John" });
        trace("4. Main thread execution");

        // Wait for the threads
        // Better and a TODO: return a promise from the trigger method so we can wait for promise.resolve()
        Sys.sleep(3);

        return 0;
    }
}