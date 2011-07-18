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

import std.stdio;
import std.array;
import std.string;
import std.conv;

import taglib;

void main(string[] args)
{
    int i;
    int seconds;
    int minutes;
    TagLib_File* file;
    TagLib_Tag* tag;
    TagLib_AudioProperties* properties;

    taglib_set_strings_unicode(false);

    args.popFront;
    
    foreach (arg; args)
    {
        writefln("******************** \"%s\" ********************\n", arg);

        file = taglib_file_new(arg.toStringz);

        if (file is null)
            break;

        tag        = taglib_file_tag(file);
        //~ file = null; // test
        properties = taglib_file_audioproperties(file);

        if (tag !is null)
        {
           writefln("-- TAG --");
           writefln("title   - \"%s\"", to!string(taglib_tag_title(tag)));
           writefln("artist  - \"%s\"", to!string(taglib_tag_artist(tag)));
           writefln("album   - \"%s\"", to!string(taglib_tag_album(tag)));
           writefln("year    - \"%s\"", to!string(taglib_tag_year(tag)));
           writefln("comment - \"%s\"", to!string(taglib_tag_comment(tag)));
           writefln("track   - \"%s\"", to!string(taglib_tag_track(tag)));
           writefln("genre   - \"%s\"", to!string(taglib_tag_genre(tag)));
        }

        if (properties !is null)
        {
            seconds = taglib_audioproperties_length(properties) % 60;
            minutes = (taglib_audioproperties_length(properties) - seconds) / 60;

            writefln("-- AUDIO --\n");
            writefln("bitrate     - %s", to!string(taglib_audioproperties_bitrate(properties)));
            writefln("sample rate - %s", to!string(taglib_audioproperties_samplerate(properties)));
            writefln("channels    - %s", to!string(taglib_audioproperties_channels(properties)));
            writefln("length      - %s:%02s", minutes, seconds);
        }

        taglib_tag_free_strings();
        taglib_file_free(file);
    }
}
