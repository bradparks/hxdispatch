class Cascade
{
    public static function main():Void
    {
        var c = new hxdispatch.Cascade<Int>();

        c.initially(function(nr:Int):Int {
            return nr + 1;
        })
        .then(function(nr:Int):Int {
            return nr * 2;
        })
        .then(function(nr:Int):Int {
            return nr;
        })
        .finally(function(nr:Int):Int {
            return nr - 4;
        });

        trace(c.descend(3)); // ((3 + 1) * 2) - 4 = 4
    }
}
