# Examples

> Various ready-to-use code examples showing how to use the `hxdispatch`
> library.

## Cascade

```haxe
import hxdispatch.async.Cascade;
import hxdispatch.async.Future;
import hxstd.threading.ExecutionContext;

var c:Cascade<Int> = new Cascade<Int>(ExecutionContext.parallelExecutor);

c.then(function(arg:Int):Int {
    return arg + 2;
});
c.then(function(arg:Int):Int {
    return arg * 2;
});

var f:Future<Int> = c.plunge(2); // non-blocking call
trace(f.get(true));              // should output '8'
```

## Future

```haxe
import hxdispatch.async.Future;
import hxstd.vm.Thread;

var f:Future<Int> = new Future<Int>();
Thread.create(function():Void {
    trace(f.get(true)); // blocks until Future is resolved, should output '5'
});

f.resolve(5);
Sys.sleep(1); // for demo, ensures Thread had time to do its work
```

## Dispatcher

```haxe
import hxdispatch.Dispatcher.Status;
import hxdispatch.async.Dispatcher;
import hxdispatch.async.Dispatcher.Feedback;
import hxdispatch.async.Promise;
import hxstd.threading.ExecutionContext;
import hxstd.vm.Thread;
import hxstd.Nil;

var d:Dispatcher<Int> = new Dispatcher<Int>(ExecutionContext.parallelExecutor);

d.register("event");
d.attach("event", function(arg:Int):Void {
    trace(arg); // should output '2'
});

var f:Feedback = d.trigger("event", 2); // non-blocking trigger
if (f.status == Status.TRIGGERED) {
    f.promise.await(); // blocks until all callbacks are executed
}
```

## Promise

```haxe
import hxdispatch.async.Promise;
import hxstd.threading.ExecutionContext;

var p:Promise<Int> = new Promise<Int>(ExecutionContext.parallelExecutor);

p.done(function(arg:Int):Void {
    trace("Rejected or resolved");
});
p.rejected(function(arg:Int):Void {
    trace("Rejected");
});
p.resolved(function(arg:Int):Void {
    trace("Resolved");
});
Promise.when([p]).done(function(arg:Int):Void {
    trace("All callbacks executed");
});

p.resolve(5); // non-blocking resolve, triggers 'done' and 'resolved'
p.await();    // blocks until callbacks are executed
Sys.sleep(1); // demo only, ensure Promise.when Thread has done its work
```