package hxdispatch;

/**
 *
 */
typedef Event = String;


/**
 *
 */
abstract Args(Dynamic)
{
    private inline function new(value:Dynamic):Void
    {
        this = value;
    }

    @:from
    public static inline function fromBool(b:Bool):Args
    {
        return new Args(b);
    }

    @:from
    public static inline function fromDynamic(d:Dynamic):Args
    {
        return new Args(d);
    }

    @:from
    public static inline function fromFloat(f:Float):Args
    {
        return new Args(f);
    }

    @:from
    public static inline function fromInt(i:Int):Args
    {
        return new Args(i);
    }

    @:from
    public static inline function fromString(s:String):Args
    {
        return new Args(s);
    }
}
