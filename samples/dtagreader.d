/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +
 +  Run via: dtagreader "C:\My Music\track.mp3" "C:\My Music\track2.mp3"
 +/

module dtagreader;

import std.stdio;
import std.array;
import std.string;
import std.conv;

import taglib.taglib;

void main(string[] args)
{
    int i;
    int seconds;
    int minutes;
    
    TagLibFile file;

    args.popFront;    
    foreach (arg; args)
    {
        writefln("******************** \"%s\" ********************\n", arg);

        file = new TagLibFile(arg);

        writeln("-- TAG --");
        writefln("title   - \"%s\"", file.tags.title);
        writefln("artist  - \"%s\"", file.tags.artist);
        writefln("album   - \"%s\"", file.tags.album);
        writefln("year    - \"%s\"", file.tags.year);
        writefln("comment - \"%s\"", file.tags.comment);
        writefln("track   - \"%s\"", file.tags.track);
        writefln("genre   - \"%s\"", file.tags.genre);

        seconds = file.audio.length % 60;
        minutes = (file.audio.length - seconds) / 60;

        writefln("-- AUDIO --\n");
        writefln("bitrate     - %s", file.audio.bitrate);
        writefln("sample rate - %s", file.audio.samplerate);
        writefln("channels    - %s", file.audio.channels);
        writefln("length      - %s:%02s", minutes, seconds);

        file.close();  // do not access file after closing it
    }
}
