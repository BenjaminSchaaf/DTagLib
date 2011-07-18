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

// @BUG@: DMD 2.054 CTFE bug http://d.puremagic.com/issues/show_bug.cgi?id=6344
//~ private string wrapEnum(Type)(string newName, string oldName, string prefix)
//~ {
    //~ import std.traits;
    
    //~ string result = "enum " ~ newName ~ " {";
    
    //~ foreach (member; EnumMembers!Type)
    //~ {
        //~ result ~= to!string(member).replace(prefix, "") ~ " = " ~ oldName ~ "." ~ to!string(member) ~ ",";
    //~ }

    //~ return result[0..$-1] ~ "}";
//~ }

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

class TagLibUnsavedChangesException : Exception
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

class TagLibFile
{
    enum ForceClose
    {
        False,
        True
    }
    
    // @BUG@: DMD 2.054 CTFE bug http://d.puremagic.com/issues/show_bug.cgi?id=6344
    //~ mixin(wrapEnum!(TagLib_File_Type)("FileType", "TagLib_File_Type", "TagLib_File_"));
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
    
    this(string fileName, ForceClose force = ForceClose.False)
    {
        openFile(fileName, force);
    }
    
    this(string fileName, FileType fileType, ForceClose force = ForceClose.False)
    {
        openFile(fileName, fileType, force);
    }        
    
    // @BUG@ Why is this never called even on explicit clear()/delete ??
    ~this()
    {
        close();
    }
    
    void openFile(string fileName, ForceClose force = ForceClose.False)
    {
        closeIfOpened(force);
        
        this.tagLibFile = taglib_file_new(fileName.toStringz);
        
        enforce(tagLibFile, new TagLibFileException(format("Couldn't open file: %s.", fileName)));
        enforce(taglib_file_is_valid(tagLibFile), 
            new TagLibFileException(format("File is either unreadable or has invalid information: %s.", fileName)));
        
        this.fileName = fileName;
        initProperties();
    }
    
    void openFile(string fileName, FileType fileType, ForceClose force = ForceClose.False)
    {
        closeIfOpened(force);
        
        this.tagLibFile = taglib_file_new_type(fileName.toStringz, cast(TagLib_File_Type)fileType);
        
        enforce(tagLibFile, new TagLibFileException(format("Couldn't open file: %s of type %s.", fileName, fileType)));
        enforce(taglib_file_is_valid(tagLibFile), 
            new TagLibFileException(format("File is either unreadable or has invalid information: %s.", fileName)));
        
        this.fileName = fileName;
        initProperties();
    }
    
    void close(ForceClose force = ForceClose.False)
    {
        debug
        {
            assert(tagLibFile !is null, format("Can't close an uninitialized TagLibFile for file: %s", fileName));
        }
        else
        {
            if (tagLibFile is null)
                return;
        }

        tags.free();
        
        if (!dirty || (dirty && (force == ForceClose.True)))
        {
            taglib_file_free(tagLibFile);
            tagLibFile = null;
            fileName = null;
            dirty = false;
            clearProperties();
        }
        else
        {
            throw new TagLibUnsavedChangesException(format("Cannot unforcefully close file while changes are left unsaved: %s.", fileName));
        }
    }
    
    void save()
    {
        enforce(tagLibFile !is null, new TagLibUninitializedException("Can't save uninitialized TagLibFile."));
        
        auto result = taglib_file_save(tagLibFile);
        enforce(result, new TagLibFileSaveException(format("Saving %s failed.", fileName)));
        dirty = false;
    }
    
    TagLibAudioProperties audio;
    TagLibTag tags;
    
private:

    void closeIfOpened(ForceClose force)
    {
        if (tagLibFile !is null)
        {
            close(force);
        }
    }

    void initProperties()
    {
        enforce(tagLibFile !is null, new TagLibUninitializedException("Can't load Tags from uninitialized TagLibFile."));
        enforce(taglib_file_is_valid(tagLibFile), new TagLibFileException(format("File is invalid: %s", fileName)));
        
        tags  = new TagLibTag(tagLibFile, fileName);
        audio = new TagLibAudioProperties(tagLibFile, fileName);
    }

    void clearProperties()
    {
        audio = null;
        tags = null;
        
        /+ @BUG@ This throws at runtime from within tag_c.dll.
         + I'm not too sure what's going on, it could be that TagLib
         + is trying to access *tagLibFile after the GC nukes it..
         + If I could make this work I could catch invalid access
         + at runtime to prevent crashes.
         + 
         + If you're an ASM/memory geek feel free to investigate. :)
         +/
        version (Disabled)
        {
            audio = new RuntimeGuard!TagLibAudioProperties(null, null);
            tags  = new RuntimeGuard!TagLibTag(null, null);
        }
    }    
    
    TagLib_File* tagLibFile;
    
    string fileName;
    bool dirty;    
}

class TagLibTagException : Exception
{
    this(string msg)
    {
        super(msg);
    }        
}

private class TagLibTag
{
    this(TagLib_File* tagLibFile, string fileName)
    {
        tagLibTag = taglib_file_tag(tagLibFile);
        enforce(tagLibTag !is null, new TagLibTagException(format("Failed to create Tags from: %s.", fileName)));
    }
    
    enum Encoding
    {
        Latin1 = TagLib_ID3v2_Encoding.TagLib_ID3v2_Latin1,
        UTF16 = TagLib_ID3v2_Encoding.TagLib_ID3v2_UTF16,
        UTF16BE = TagLib_ID3v2_Encoding.TagLib_ID3v2_UTF16BE,        
        UTF8 = TagLib_ID3v2_Encoding.TagLib_ID3v2_UTF8,
    }    
    
    @property void encoding(Encoding encoding)
    {
        taglib_id3v2_set_default_text_encoding(cast(TagLib_ID3v2_Encoding)encoding);
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
        taglib_tag_set_title(tagLibTag, title.toStringz);
    }    
    
    @property void artist(string artist)
    {
        taglib_tag_set_artist(tagLibTag, artist.toStringz);
    }
    
    @property void album(string album)
    {
        taglib_tag_set_album(tagLibTag, album.toStringz);
    }
    
    @property void comment(string comment)
    {
        taglib_tag_set_comment(tagLibTag, comment.toStringz);
    }
    
    @property void genre(string genre)
    {
        taglib_tag_set_genre(tagLibTag, genre.toStringz);
    }
    
    @property void year(uint year)
    {
        taglib_tag_set_year(tagLibTag, year);
    }
    
    @property void track(uint track)
    {
        taglib_tag_set_track(tagLibTag, track);
    }    
    
    void free()
    {
        taglib_tag_free_strings();
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

private class TagLibAudioProperties
{
    this(TagLib_File* tagLibFile, string fileName)
    {
        tagLibAudioProperties = taglib_file_audioproperties(tagLibFile);
        enforce(tagLibAudioProperties !is null, new TagLibAudioException(format("Failed to create AudioProperties from: %s.", fileName)));
    }    
    
    // getters
    
    @property int length()
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

private template RuntimeGuard(Base)
{
    alias AutoImplement!(Base, generateExceptionTrap, isAbstractFunction) RuntimeGuard;
}

private template generateExceptionTrap(C, func...)
{
    enum string generateExceptionTrap = `throw new TagLibUninitializedException("Tried to access properties of TagLibFile before it was properly initialized.");`;
}
