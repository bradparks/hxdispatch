#if cpp
    import cpp.vm.Thread;
#elseif java
    import java.vm.Thread;
#elseif neko
    import neko.vm.Thread;
#else
    #error "Not supported on target plattform."
#end

class Future
{
    public static function main():Void
    {
        var f = new hxdispatch.concurrent.Future<String>();

        Thread.create(function():Void {
            trace(f.get(true));
        });
        Thread.create(function():Void {
            trace(f.get(true));
        });

        Sys.sleep(2);
        f.resolve("Resolved Future");

        Sys.sleep(1); // demo only, so Thread traces before exit
    }
}
