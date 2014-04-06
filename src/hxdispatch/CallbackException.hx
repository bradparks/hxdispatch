package hxdispatch;

import haxe.PosInfos;
import hxstd.Exception;

/**
 *
 */
class CallbackException extends Exception
{
    /**
     * @{inherit}
     */
    public function new(?msg:String = "Exception thrown in callback function", ?info:PosInfos):Void
    {
        super(msg, info);
    }
}
