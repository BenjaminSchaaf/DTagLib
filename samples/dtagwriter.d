/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +/

/+
 + Run via: dtagwriter "test.mp3"
 + Warning: This will overwrite your existing tags, be careful.
 +/

module dtagwriter;

import std.stdio;
import std.array;
import std.string;
import std.conv;

import taglib.taglib;

void main(string[] args)
{
    TagFile file;

    args.popFront;    
    foreach (arg; args)
    {
        file = TagFile(arg);

        file.tags.title = "The New " ~ file.tags.title;
        file.tags.artist = "The New " ~ file.tags.artist;
        file.tags.album = "The Best Of " ~ file.tags.album;
        
        writefln("title   - \"%s\"", file.tags.title);
        writefln("artist  - \"%s\"", file.tags.artist);
        writefln("album   - \"%s\"", file.tags.album);

        file.save();   // call save to write changes
    }
}
