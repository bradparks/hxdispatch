package hxdispatch;

import haxe.PosInfos;
import hxstd.Exception;

/**
 * Exception to signalize problems in the workflow/code flow
 * or errors/problems caused by synchronization between threads.
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
