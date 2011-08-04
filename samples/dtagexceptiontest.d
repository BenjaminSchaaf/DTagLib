/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +/

/+
 + Run via: dtagexceptiontest "test.mp3"
 + Tests various exceptions being thrown.
 +/

module dtagexceptiontest;

import std.array;
import std.exception;
import std.stdio;
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

        bool failedSave;
        try
        {
            file.save();
        }
        catch (TagLibException exc)
        {
            failedSave = true;
        }
        
        enforce(!failedSave);
        
        file = TagFile(arg);
        
        file.tags.title = file.tags.title;
        file.tags.artist = file.tags.artist;
        file.tags.album = file.tags.album;
        
        enforce(file.tags.dirty);
        
        file.save();
        
        enforce(!file.tags.dirty);
    }
}
