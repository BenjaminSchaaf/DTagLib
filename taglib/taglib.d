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
import std.traits;

import taglib.c.taglib;

// Todo: These need to be verified to be reasonable defaults
static this()
{
    taglib_set_strings_unicode(true);
    taglib_set_string_management_enabled(false);
    taglib_id3v2_set_default_text_encoding(TagLib_ID3v2_Encoding.TagLib_ID3v2_UTF8);
}

class TagLibUninitializedException : Exception
{
    this(string msg)
    {
        super(msg);
    }    
}

class TagLibFileException : Exception
{
    this(string msg)
    {
        super(msg);
    }        
}

class TagLibFileSaveException : Exception
{
    this(string msg)
    {
        super(msg);
    }        
}

final class TagFile
{
    enum FileType
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
    
    this(string tagFileName)
    {
        openFile(tagFileName);
    }
    
    ~this()
    {
        close();
    }
    
    void openFile(string tagFileName)
    {
        closeIfOpened();
        
        tagFile = taglib_file_new(tagFileName.toStringz);
        
        enforce(tagFile, new TagLibFileException(format("Couldn't open file: %s.", tagFileName)));
        enforce(taglib_file_is_valid(tagFile), 
            new TagLibFileException(format("File is either unreadable or has invalid information: %s.", tagFileName)));
        
        this.tagFileName = tagFileName;
        initProperties();
    }
    
    void openFile(string tagFileName, FileType fileType)
    {
        closeIfOpened();
        
        tagFile = taglib_file_new_type(tagFileName.toStringz, cast(TagLib_File_Type)fileType);
        
        enforce(tagFile, new TagLibFileException(format("Couldn't open file: %s of type %s.", tagFileName, fileType)));
        enforce(taglib_file_is_valid(tagFile), 
            new TagLibFileException(format("File is either unreadable or has invalid information: %s.", tagFileName)));
        
        this.tagFileName = tagFileName;
        initProperties();
    }
    
    void close()
    {
        if (tagFile is null)
            return;

        taglib_tag_free_strings();
        taglib_file_free(tagFile);
        tagFile = null;
        
        /+
         + Originally I thought about using AutoImplement to make a guard class, but this is 
         + impossible since AutoImplement expects a template that returns a string. I can't pass
         + a custom exception to AutoImplement.
         +/
        tags = null;
        audio = null;
    }
    
    void save()
    {
        enforce(tagFile !is null, new TagLibUninitializedException("Can't save uninitialized TagFile."));
        
        auto result = taglib_file_save(tagFile);
        enforce(result, new TagLibFileSaveException(format("Saving %s failed.", tagFileName)));
        tags.save();
    }
    
    // if only there was a simple forward mechanism for specific methods..
    auto getTags()
    {
        return tags.getTags();
    }
    
    auto setTags(T)(T t)
    {
        return tags.setTags(t);
    }    
    
    auto getAudioInfo()
    {
        return audio.getAudioInfo();
    }
    
    TagLibAudio audio;
    TagLibTag tags;
    
private:

    void closeIfOpened()
    {
        if (tagFile !is null)
        {
            close();
        }
    }

    void initProperties()
    {
        enforce(tagFile !is null, new TagLibUninitializedException("Can't load Tags from uninitialized TagFile."));
        enforce(taglib_file_is_valid(tagFile), new TagLibFileException(format("File is invalid: %s", tagFileName)));
        
        tags  = new TagLibTag(tagFile, tagFileName);
        audio = new TagLibAudio(tagFile, tagFileName);
    }
    
    TagLib_File* tagFile;
    string tagFileName;
}

class TagLibTagException : Exception
{
    this(string msg)
    {
        super(msg);
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

final class TagLibTag
{
    enum Encoding
    {
        Latin1 = TagLib_ID3v2_Encoding.TagLib_ID3v2_Latin1,
        UTF16 = TagLib_ID3v2_Encoding.TagLib_ID3v2_UTF16,
        UTF16BE = TagLib_ID3v2_Encoding.TagLib_ID3v2_UTF16BE,        
        UTF8 = TagLib_ID3v2_Encoding.TagLib_ID3v2_UTF8,
    }    
    
    bool _dirty;
    
    this()
    {
    }
    
    this(TagLib_File* tagFile, string tagFileName)
    {
        tagLibTag = taglib_file_tag(tagFile);
        enforce(tagLibTag !is null, new TagLibTagException(format("Failed to create Tags from: %s.", tagFileName)));
    }
    
    void save()
    {
        _dirty = false;
    }
    
    @property void encoding(Encoding encoding)
    {
        taglib_id3v2_set_default_text_encoding(cast(TagLib_ID3v2_Encoding)encoding);
    }
    
    @property void setTags(Tags tags)
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
    
    @property Tags getTags()
    {
        Tags tags;
        with (tags)
        {
            title   = this.title;
            artist  = this.artist;
            album   = this.album;
            comment = this.comment;
            genre   = this.genre;
            year    = this.year;
            track   = this.track;
        }
        return tags;
    }
    
    // getters
    
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
    
    void free()
    {
        dirty = false;
        taglib_tag_free_strings();
    }
    
    @property void dirty(bool state)
    {
        _dirty = state;
    }
    
    @property bool dirty()
    {
        return _dirty;
    }
    
    private TagLib_Tag* tagLibTag;
}

class TagLibAudioException : Exception
{
    this(string msg)
    {
        super(msg);
    }        
}

struct AudioInfo
{
    int time;
    int bitrate;  
    int samplerate;
    int channels; 
}

final class TagLibAudio
{
    this()
    {
    }
    
    this(TagLib_File* tagFile, string tagFileName)
    {
        tagLibAudioProperties = taglib_file_audioproperties(tagFile);
        enforce(tagLibAudioProperties !is null, new TagLibAudioException(format("Failed to create AudioProperties from: %s.", tagFileName)));
    }    
    
    // getters
    
    @property AudioInfo getAudioInfo()
    {
        AudioInfo audio;
        with (audio)
        {
            time   = this.time;
            bitrate  = this.bitrate;
            samplerate = this.samplerate;
            channels = this.channels;
        }
        return audio;
    }    
    
    @property int time()
    {
        return taglib_audioproperties_length(tagLibAudioProperties);
    }
    
    @property int bitrate()
    {
        return taglib_audioproperties_bitrate(tagLibAudioProperties);
    }
    
    @property int samplerate()
    {
        return taglib_audioproperties_samplerate(tagLibAudioProperties);
    }
    
    @property int channels()
    {
        return taglib_audioproperties_channels(tagLibAudioProperties);
    }   
   
    private TagLib_AudioProperties* tagLibAudioProperties;
}
