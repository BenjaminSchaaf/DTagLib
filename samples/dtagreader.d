/* Copyright (C) 2003 Scott Wheeler <wheeler@kde.org>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/+
 + Ported to the D2 Programming Language by Andrej Mitrovic, 2011.
 + 
 + Run via: dtagreader "C:\My Music\track.mp3" "C:\My Music\track2.mp3"
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
    
    TagFile file;

    args.popFront;    
    foreach (arg; args)
    {
        writefln("******************** \"%s\" ********************\n", arg);

        file = new TagFile(arg);

        writeln("-- TAG --");
        writefln("title   - \"%s\"", file.tags.title);
        writefln("artist  - \"%s\"", file.tags.artist);
        writefln("album   - \"%s\"", file.tags.album);
        writefln("year    - \"%s\"", file.tags.year);
        writefln("comment - \"%s\"", file.tags.comment);
        writefln("track   - \"%s\"", file.tags.track);
        writefln("genre   - \"%s\"", file.tags.genre);

        seconds = file.audio.time % 60;
        minutes = (file.audio.time - seconds) / 60;

        writefln("-- AUDIO --\n");
        writefln("bitrate     - %s", file.audio.bitrate);
        writefln("sample rate - %s", file.audio.samplerate);
        writefln("channels    - %s", file.audio.channels);
        writefln("length      - %s:%02s", minutes, seconds);

        file.close();  // do not access file after closing it
    }
}
