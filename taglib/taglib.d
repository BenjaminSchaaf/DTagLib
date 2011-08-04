/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +/

module taglib.taglib;

import std.conv;
import std.exception;
import std.string;
import std.typecons;

import taglib.c.taglib;

static this()
{
    taglib_set_strings_unicode(true);
    taglib_set_string_management_enabled(true);
    taglib_id3v2_set_default_text_encoding(TagLib_ID3v2_Encoding.TagLib_ID3v2_UTF8);
}

class TagLibException : Exception
{
    this(string msg) { super(msg); }
}

enum TagFileType
{
    MPEG = TagLib_File_Type.TagLib_File_MPEG,
    OggVorbis = TagLib_File_Type.TagLib_File_OggVorbis,
    FLAC = TagLib_File_Type.TagLib_File_FLAC,
    MPC = TagLib_File_Type.TagLib_File_MPC,
    OggFlac = TagLib_File_Type.TagLib_File_OggFlac,
    WavPack = TagLib_File_Type.TagLib_File_WavPack,
    Speex = TagLib_File_Type.TagLib_File_Speex,
    TrueAudio = TagLib_File_Type.TagLib_File_TrueAudio,
    MP4 = TagLib_File_Type.TagLib_File_MP4,
    ASF = TagLib_File_Type.TagLib_File_ASF,
}

struct TagFile
{
    struct Payload
    {
        this(string filename)
        {
            tagFile = taglib_file_new(filename.toStringz);

            enforce(tagFile, new TagLibException(format("Couldn't open file: %s.", filename)));
            enforce(taglib_file_is_valid(tagFile),
                new TagLibException(format("File is either unreadable or has invalid information: %s.", filename)));

            tagFileName = filename;
            initProperties();
            initialized = true;
        }

        this(string filename, TagFileType filetype)
        {
            tagFile = taglib_file_new_type(filename.toStringz, cast(TagLib_File_Type)filetype);

            enforce(tagFile, new TagLibException(format("Couldn't open file: %s of type %s.", filename, filetype)));
            enforce(taglib_file_is_valid(tagFile),
                new TagLibException(format("File is either unreadable or has invalid information: %s.", filename)));

            tagFileName = filename;
            initProperties();
            initialized = true;
        }

        ~this()
        {
            if (tagFile !is null)  // Refcounted bug: dtor is being called for no reason before the ctor is called.
            {
                initialized = false;
                taglib_tag_free_strings();
                taglib_file_free(tagFile);
                tagFile = null;
            }
        }

        void initProperties()
        {
            enforce(taglib_file_is_valid(tagFile), new TagLibException(format("File is invalid: %s", tagFileName)));

            audio = TagLibAudio(tagFile, tagFileName);
            tags  = TagLibTag(tagFile, tagFileName);
        }

        void save()
        {
            auto result = taglib_file_save(tagFile);
            enforce(result, new TagLibException(format("Saving %s failed.", tagFileName)));
            tags.dirty = false;
        }

        this(this) { assert(false); }
        void opAssign(TagFile.Payload rhs) { assert(false); }

        bool initialized;
        string tagFileName;
        TagLib_File* tagFile;

        TagLibAudio audio;
        TagLibTag tags;
    }

    private alias RefCounted!(Payload, RefCountedAutoInitialize.yes) Data;
    private Data _data;

    this(string filename)
    {
        _data = Data(filename);
    }

    this(string filename, TagFileType filetype)
    {
        _data = Data(filename, filetype);
    }

    void save()
    {
        enforce(_data.initialized, new TagLibException("TagFile is uninitialized."));
        _data.save();
    }

    @property ref TagLibTag tags()
    {
        enforce(_data.initialized, new TagLibException("TagFile is uninitialized."));
        return _data.tags;
    }

    @property ref TagLibAudio audio()
    {
        enforce(_data.initialized, new TagLibException("TagFile is uninitialized."));
        return _data.audio;
    }
}

struct Tags
{
    string title;
    string artist;
    string album;
    string comment;
    string genre;
    uint year;
    uint track;
}

enum TagEncoding
{
    Latin1 = TagLib_ID3v2_Encoding.TagLib_ID3v2_Latin1,
    UTF16 = TagLib_ID3v2_Encoding.TagLib_ID3v2_UTF16,
    UTF16BE = TagLib_ID3v2_Encoding.TagLib_ID3v2_UTF16BE,
    UTF8 = TagLib_ID3v2_Encoding.TagLib_ID3v2_UTF8,
}

private struct TagLibTag
{
    this(TagLib_File* tagFile, string tagFileName)
    {
        tagLibTag = taglib_file_tag(tagFile);
        enforce(tagLibTag !is null, new TagLibException(format("Failed to create Tags from: %s.", tagFileName)));
    }

    @property void encoding(TagEncoding encoding)
    {
        taglib_id3v2_set_default_text_encoding(cast(TagLib_ID3v2_Encoding)encoding);
    }

    @property void tags(Tags tags)
    {
        with (tags)
        {
            this.title = title;
            this.artist = artist;
            this.album = album;
            this.comment = comment;
            this.genre = genre;
            this.year = year;
            this.track = track;
        }
    }

    // getters

    @property Tags tags()
    {
        return Tags
        (
            this.title,
            this.artist,
            this.album,
            this.comment,
            this.genre,
            this.year,
            this.track
        );
    }

    @property string title()
    {
        return to!string(taglib_tag_title(tagLibTag));
    }

    @property string artist()
    {
        return to!string(taglib_tag_artist(tagLibTag));
    }

    @property string album()
    {
        return to!string(taglib_tag_album(tagLibTag));
    }

    @property string comment()
    {
        return to!string(taglib_tag_comment(tagLibTag));
    }

    @property string genre()
    {
        return to!string(taglib_tag_genre(tagLibTag));
    }

    @property uint year()
    {
        return taglib_tag_year(tagLibTag);
    }

    @property uint track()
    {
        return taglib_tag_track(tagLibTag);
    }

    // setters

    @property void title(string title)
    {
        dirty = true;
        taglib_tag_set_title(tagLibTag, title.toStringz);
    }

    @property void artist(string artist)
    {
        dirty = true;
        taglib_tag_set_artist(tagLibTag, artist.toStringz);
    }

    @property void album(string album)
    {
        dirty = true;
        taglib_tag_set_album(tagLibTag, album.toStringz);
    }

    @property void comment(string comment)
    {
        dirty = true;
        taglib_tag_set_comment(tagLibTag, comment.toStringz);
    }

    @property void genre(string genre)
    {
        dirty = true;
        taglib_tag_set_genre(tagLibTag, genre.toStringz);
    }

    @property void year(uint year)
    {
        dirty = true;
        taglib_tag_set_year(tagLibTag, year);
    }

    @property void track(uint track)
    {
        dirty = true;
        taglib_tag_set_track(tagLibTag, track);
    }

    @property void dirty(bool state)
    {
        _dirty = state;
    }

    @property bool dirty()
    {
        return _dirty;
    }

    private bool _dirty;
    private TagLib_Tag* tagLibTag;
}

struct Audio
{
    int time;
    int bitrate;
    int samplerate;
    int channels;
}

private struct TagLibAudio
{
    this(TagLib_File* tagFile, string filename)
    {
        properties = taglib_file_audioproperties(tagFile);
        enforce(properties !is null, new TagLibException(format("Failed to create AudioProperties from: %s.", filename)));
    }

    // getters

    @property Audio audio()
    {
        return Audio
        (
            this.time,
            this.bitrate,
            this.samplerate,
            this.channels
        );
    }

    @property int time()
    {
        return taglib_audioproperties_length(properties);
    }

    @property int bitrate()
    {
        return taglib_audioproperties_bitrate(properties);
    }

    @property int samplerate()
    {
        return taglib_audioproperties_samplerate(properties);
    }

    @property int channels()
    {
        return taglib_audioproperties_channels(properties);
    }

    private TagLib_AudioProperties* properties;
}
