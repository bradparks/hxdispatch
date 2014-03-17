package hxdispatch.threaded;

/**
 * Signal send between threads in Future/Promise context to signalize
 * when one of them has been marked as ready/done.
 */
enum Signal
{
    READY;
}
