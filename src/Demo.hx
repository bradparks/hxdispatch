import maddinxx.hxdispatch.Args;
import maddinxx.hxdispatch.Callback;
import maddinxx.hxdispatch.Dispatcher;
import maddinxx.hxdispatch.Feedback;
import maddinxx.hxdispatch.Feedback.Status;
import maddinxx.hxdispatch.Promise;
import maddinxx.hxdispatch.SyncedDispatcher;
import maddinxx.hxdispatch.ThreadedDispatcher;

typedef Dispatcher = ThreadedDispatcher;

class Demo
{
    public static function main():Int
    {
        var callback:Callback = function(args:Args):Void {
            trace("\t\tPosition not defined...");
            Sys.sleep(1);
            trace("6. Callback thread executed");
        };

        var dispatcher = new Dispatcher();
        dispatcher.onEvent("_eventTriggered", function(args:Args):Void {
            trace("\t\tInternal event triggered");
        });

        dispatcher.registerEvent("demo", callback);
        trace("1. registered event");

        dispatcher.onEvent("demo", function(args:Args):Void {
            trace("\t\tPosition not defined...");
            Sys.sleep(0.2);
            trace("5. Callback thread executed");
        });
        trace("2. Added another callback");

        trace("3. Triggering events");
        var feedback:Feedback = dispatcher.trigger("demo", { name: "John" });
        trace("4. Main thread execution");

        if (feedback.status == Status.TRIGGERED) {
            feedback.promise.wait();
        }

        return 0;
    }
}
