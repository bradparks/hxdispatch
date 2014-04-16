package hxdispatch;

/**
 * Event typedef used by the Dispatchers.
 *
 * Since Haxe Maps don't allow generic type parameters we rely on a toString() method
 * that is used to identify an Event.
 * This might be replaced with a smarter variant some day.
 */
typedef Event = Dynamic;
