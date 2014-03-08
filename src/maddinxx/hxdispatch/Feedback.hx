package maddinxx.hxdispatch;

import maddinxx.hxdispatch.Promise;

typedef Feedback =
{
    var status:Status;
    #if (cpp || java || neko)
    @:optional var promise:Promise;
    #end
};

enum Status
{
    NO_SUCH_EVENT;
    OK;
    TRIGGERED;
}
