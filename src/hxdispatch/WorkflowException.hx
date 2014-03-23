package hxdispatch;

import haxe.PosInfos;
import hxstd.Exception;

/**
 *
 */
class WorkflowException extends Exception
{
    /**
     * @{inherit}
     */
    public function new(?msg:String = "Error in workflow logic/synchronization", ?info:PosInfos):Void
    {
        super(msg, info);
    }
}
