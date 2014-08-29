#DTagLib

This is a D wrapper library of the TagLib library (abstract API only).

The library has been tested on Windows XP 32bit and Ubuntu 32bit systems.

Project Homepage: https://github.com/AndrejMitrovic/DTagLib
    
##Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE. 

##Building

Use `dub` to build the library files:

```
dub build
```


##Dependencies

The TagLib shared libraries for the C binding are required. On linux TagLib might already exist as a precompiled package, see your package manager.

##Using DTagLib

TagLib is straightforward to use. Simply instantiate a TagFile class with the path of an audio file:

```
auto tagFile = new TagFile(r"C:\My Music\Artist - Track.mp3");
```

And then read/modify the file's tags, and read any audio information if you want to:

```
with (tagFile.tags)
{
    writeln(artist);  // read
    year = 2000;      // modify
}

writeln(tagFile.audio.samplerate);  // audio properties can only be read
```

Also see the various examples in the samples folder.

##Contact

To contact me, send me a message via Github @ https://github.com/AndrejMitrovic, or e-mail me at: andrej.mitrovich@gmail.com

##ToDo

- Make more examples, maybe utilizing a GUI library like gtkD.

##Contributors

Johannes Pfau tested and verified that DTagLib works on Linux.
He also contributed with DTagLib and TagLib patches and helped improve the
memory management of DTagLib. Thanks, Johannes!
    
##Acknowledgments

Thanks to Scott Wheeler and all other developers and contributors of the TagLib project.

##Links

D2 Programming Language Homepage: http://d-programming-language.org/
TagLib homepage: http://developer.kde.org/~wheeler/taglib.html
