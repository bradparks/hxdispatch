import maddinxx.hxdispatch.Args;
import maddinxx.hxdispatch.Callback;
import maddinxx.hxdispatch.Dispatcher;
import maddinxx.hxdispatch.Feedback;
import maddinxx.hxdispatch.Feedback.Status;
#if (cpp || java || neko)
import maddinxx.hxdispatch.ThreadedDispatcher;
#end

#if (cpp || java || neko)
typedef Dispatcher = ThreadedDispatcher;
#end

class Demo
{
    public static function main():Int
    {
        var start = haxe.Timer.stamp();

        var callback:Callback = function(args:Args):Void {
            trace("\t\tPosition not defined...");
            #if (cpp || cs || java || neko)
            Sys.sleep(1);
            #end
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
            #if (cpp || cs || java || neko)
            Sys.sleep(0.2);
            #end
            trace("5. Callback thread executed");
        });
        trace("2. Added another callback");

        trace("3. Triggering events");
        var feedback:Feedback = dispatcher.trigger("demo", { name: "John" });
        trace("4. Main thread execution");

        if (feedback.status == Status.TRIGGERED) {

        }

        var duration = haxe.Timer.stamp() - start;
        trace(duration);

        return 0;
    }
}
