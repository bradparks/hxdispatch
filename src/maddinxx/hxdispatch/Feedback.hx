package maddinxx.hxdispatch;

import maddinxx.hxdispatch.Promise;

typedef Feedback =
{
    var status:Status;
    @:optional var promise:Promise;
};

enum Status
{
    NO_SUCH_EVENT;
    OK;
    TRIGGERED;
}
