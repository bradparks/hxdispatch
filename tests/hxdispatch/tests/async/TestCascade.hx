package hxdispatch.tests.async;

import hxdispatch.async.Cascade;

/**
 * TestSuite for the hxdispatch.async.Cascade class.
 *
 * TODO: mock ThreadExecutor
 */
class TestCascade extends hxdispatch.tests.concurrent.TestCascade
{
    /**
     * @{inherit}
     */
    override public function setup():Void
    {
        this.cascade = new Cascade<Int>(new hxstd.threading.ThreadExecutor());
    }


    /**
     * Checks that the plunge() method returns the input argument when no Tiers
     * have been added yet. Also makes sure, it returns a Future.
     */
    public function testPlunge():Void
    {
        var input:Int = 5;
        assertEquals(input, (untyped this.cascade.plunge(input)).get(true));
    }

    /**
     * Checks if the plunge() method iterates over a copy of the added Tiers.
     *
     * It could be that Tiers add other Tiers to the Cascade, which could bring
     * problem with it. Therefor the plunge() method should iterate over a copy
     * of all "til-then" added Tiers.
     *
     * Attn: This test depends on the then() method - make sure all tests for that
     * method work before looking for errors in plunge() when this test fails.
     */
    public function testPlungeIteratesOverCopy():Void
    {
        this.cascade.then(function(arg:Int):Int {
            this.cascade.then(function(arg:Int):Int {
                return arg * 2;
            });
            return arg;
        });
        assertEquals((untyped this.cascade.plunge(2)).get(true), 2);
        assertEquals((untyped this.cascade.plunge(2)).get(true), 4);
    }
}
