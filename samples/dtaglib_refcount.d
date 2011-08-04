/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +/

/+
 + Tests if the refcount implementation works as expected.
 +/

module dtaglib_refcount;

import std.stdio;
import std.array;
import std.string;
import std.conv;

import taglib.taglib;

TagFile globTag;
/+
 + @BUG@: globals that use Refcounted don't get their dtor called on app exit:
 + http://d.puremagic.com/issues/show_bug.cgi?id=6437
 +/

void main(string[] args)
{
    args.popFront;    
    foreach (arg; args)
    {
        loadTags(arg);
        
        writefln("title   - \"%s\"", globTag.tags.title);
        writefln("artist  - \"%s\"", globTag.tags.artist);
        writefln("album   - \"%s\"", globTag.tags.album);
    }
}  // the dtor should be called here, however see @BUG@ above.

void loadTags(string filename)
{
    TagFile temp = TagFile(filename);
    writeln("temp constructed");
    
    scope(exit)
        writeln("temp destructed");
    
    globTag = temp;  // this should increase refcount
    writeln("glob copied");
}  // after exit of scope, refcount should be decreased to 1
