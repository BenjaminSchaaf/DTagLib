module build;

import core.thread : Thread, dur;
import std.algorithm;
import std.array;
import std.exception;
import std.stdio;
import std.string;
import std.path;
import std.file;
import std.process;
import std.parallelism;

alias reduce!("a ~ ' ' ~ b") flatten;

version (Posix)
{
    enum nativeExt = "";
    enum DTagLibLocation = "./taglib/";
    enum SamplesLocation = "./samples/"; 
    enum DTagLibStatic = DTagLibLocation ~ "taglib.a";
    enum DTagLibImplib = "";
    enum ExtraLinkerFlags = "-L/usr/local/lib/libtag_c.so.0";
}
else
version (Windows)
{
    enum nativeExt = ".exe";
    enum DTagLibLocation = r".\taglib\";
    enum SamplesLocation = r".\samples\";
    enum DTagLibStatic = DTagLibLocation ~ "taglib.lib";
    enum DTagLibImplib = SamplesLocation ~ "taglib_implib.lib";
    enum ExtraLinkerFlags = "";
}

__gshared bool cleanOnly;

class FailedBuildException : Exception
{
    string[] failedMods;
    this(string[] failedModules)
    {
        this.failedMods = failedModules;
        super("");
    }    
}

string[] getFilesByExt(string dir, string ext, SpanMode spanMode = SpanMode.shallow)
{
    string[] result;
    foreach (string file; dirEntries(dir, spanMode))
    {
        if (file.isfile && (file.getExt == ext))
            result ~= file;
    }
    return result;
}

bool buildLibrary()
{
    auto sources = getFilesByExt(DTagLibLocation, "d", SpanMode.depth);
    
    auto res = system("dmd -od" ~ DTagLibLocation ~ 
                      " " ~ "-lib " ~ sources.flatten);
    
    if (res != 0)
        return false;
    
    return true;
}

bool buildProject(string sourcefile)
{
    auto res = system("dmd -of" ~ SamplesLocation ~ sourcefile.basename.getName ~ nativeExt ~ 
                      " " ~ "-od" ~ SamplesLocation ~ 
                      " " ~ DTagLibStatic ~ 
                      " " ~ DTagLibImplib ~ 
                      " " ~ ExtraLinkerFlags ~
                      " " ~ sourcefile);
    
    if (res != 0)
        return false;

    return true;
}

bool libraryExists()
{
    return DTagLibStatic.exists;
}

void buildSamples(string[] sources, bool cleanOnly = false)
{
    // has to be shared in multithreaded builds
    __gshared string[] failedBuilds;
    
    if (cleanOnly)
    {
        writeln("Cleaning..");
        try { system("del " ~ sources[0].dirname ~ r"\" ~ "*.obj > nul"); } catch {};
        try { system("del " ~ sources[0].dirname ~ r"\" ~ "*.exe > nul"); } catch {};
    }
    else
    {        
        foreach (source; parallel(sources, 1))
        {
            if (!buildProject(source))
                failedBuilds ~= source;
        }
    }
    
    enforce(!failedBuilds.length, new FailedBuildException(failedBuilds));
}

int main(string[] args)
{
    args.popFront;
    
    foreach (arg; args)
    {
        if (arg == "clean") 
        {
            cleanOnly = true;
        }
    }
    
    if (!cleanOnly && !libraryExists() && !buildLibrary())
    {
        writeln("Failed to build DTagLib library.");
        return 1;
    }    
    
    auto sources = getFilesByExt(SamplesLocation, "d");
    
    try
    {
        buildSamples(sources, cleanOnly);
    }
    catch (FailedBuildException exc)
    {
        writefln("\n%s projects failed to build:", exc.failedMods.length);
        foreach (mod; exc.failedMods)
        {
            writeln(mod);
        }
        
        return 1;
    }
    
    if (!cleanOnly)
    {
        writeln("\nAll examples succesfully built.");
    }
    
    return 0;
}
