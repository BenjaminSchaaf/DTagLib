/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +/
 
/+
 + Run via: folderstats "C:\My Music\Artist\Album\" "D:\Other Music\Artist\Album"
 + 
 + Recursively scans subdirectories of the provided paths,
 + and prints some various information back.
 +/

module folderstats;

import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.path;
import std.process;
import std.stdio;
import std.string;

import taglib.taglib;

// todo: need to extract the list of file format supported by taglib,
// and put them in the DTagLib wrapper as an enum or something.
enum audioExtensions = ["ape":0, "asf":0, "mp3":0, "flac":0, "aiff":0];

void main(string[] args)
{
    args.popFront;
    string[][] files;
    
    foreach (index, arg; args)
    {
        files.length += 1;
        foreach (string entry; dirEntries(rel2abs(arg), SpanMode.depth))
        {
            if (entry.isfile && entry.getExt in audioExtensions)
            {
                files[index] ~= entry;
            }
        }
    }
    
    foreach (sub; files)
    {
        Tags[] tags;
        
        int[] time;
        int[] bitrate;  
        int[] samplerate;
        int[] channels;         
        
        foreach (file; sub)
        {
            auto tagFile = new TagFile(file);
            
            tags ~= tagFile.getTags;
            
            time ~= tagFile.audio.time;
            bitrate ~= tagFile.audio.bitrate;
            samplerate ~= tagFile.audio.samplerate;
            channels ~= tagFile.audio.channels;
            
            tagFile.close();
        }
        
        auto printListing = format("Track listing for %s:", sub[0].dirname);
        writeln(printListing);
        writeln("-".replicate(printListing.length));  
        writeln();
        foreach (tag; tags)
        {
            printFields(tag);
            writeln();
        }

        auto audioInfo = AudioInfo(reduce!"a + b"(time) / time.length,
                                   reduce!"a + b"(bitrate) / bitrate.length,
                                   to!int(reduce!"a + b"(samplerate) / samplerate.length),
                                   to!int(reduce!"a + b"(channels) / channels.length));
        
        auto averageListing = format("Averages for %s:", sub[0].dirname);
        writeln(averageListing);
        writeln("-".replicate(averageListing.length));  
        writeln();        
        
        writefln("Average length: %s seconds.", audioInfo.time);
        writefln("Average bitrate: %s kb/s.", audioInfo.bitrate);
        writefln("Average samplerate: %s Hz.", audioInfo.samplerate);
        writefln("Average channel count: %s", audioInfo.channels);
        writeln();
    }
}

void printFields(T)(T args)
{    
    auto values = args.tupleof;
    
    auto members = [__traits(allMembers, T)];
    
    size_t max;
    size_t temp;
    foreach (index, value; values)
    {
        temp = members[index].length;
        if (max < temp) max = temp;
    }
    max += 1;
    
    foreach (index, value; values)
    {
        writefln("%-" ~ to!string(max) ~ "s: %s", members[index], value);
    }
}
