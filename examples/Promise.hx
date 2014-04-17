#if cpp
    import cpp.vm.Thread;
#elseif java
    import java.vm.Thread;
#elseif neko
    import neko.vm.Thread;
#else
    #error "Not supported on target plattform."
#end

class Promise
{
    public static function main():Void
    {
        var p = new hxdispatch.concurrent.Promise<String>();

        Thread.create(function():Void {
            p.await();
            trace("Promise marked as done and Callbacks executed.");
        });
        Thread.create(function():Void {
            p.resolved(function(arg:String):Void {
                trace("Resolved: " + arg);
            });
            p.await();
        });
        p.done(function(arg:String):Void {
            trace("Done: " + arg);
        });

        Thread.create(function():Void {
            Sys.sleep(1);
            p.resolve("Hello from Promise");
        });

        p.await(); // ensure Promise is marked as done and Callbacks executed
    }
}
