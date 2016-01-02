NOTE: The base for these modification is MonkeyX 86c from the github repository. I have cut a number of directories and file that I haven't made changes to, to decrease the download size. So you should download the 86c version from git hub and then copy over the files I have supplied to replace the ones extracted from the gihub archive. I have added two modifications to transcc and updated the template Makefiles to use them.

The first is for compiling Microsoft Windows application via a Mingw32 cross compiler tool chain on Linux and Apple Mac OS X. I have included a PDF file called cross-compiler-installation that explains on how to set up MinGW for Linux and OSX.

Due to the lack of a native Windows cross compiler tool chain to compile for Linux and OS X; coupled with Appple's licensing issues. I have not implemented cross compilation from Microsoft Windows. It's the same problem for cross compiling between Linux and OS X, though there is a cross compiler for OS X to build Linux software, but I have never test it.

The second is the ability to pass a GCC option to tell the compiler to build either a 32 bit or 64 bit executable. You can include -msize=32/64 to the transcc command line or use one of the new #GLFW features that I have added (NOD_README.TXT). Setting these options will append either 32 or 64 to the Release/Debug directory, depending on which you have selected. Not setting any options will result in the compiler using it's defaults and no extension will be used. This means that if you are using a 64bit version of TDM/GCC, then it will default to building 64 bit executables. Please note that this will only affect the GLFW2/3 targets and not the C++-Tool. You should include the -m32 or -m64 options to #CC_OPTS as part of your main Monkey source file for the C++-Tool. Also note that Glfw3+Angle use only 32bit libraries, so the compilers code generation options must be set to 32bit output. Remember that if you are using the MinGW cross compiler, it will also have to support the -m32/64 switch if you wish to do that kind of cross compiling.

If you have Visual Studio 2013/2015 installed. Then you will find that there are a couple of Visuals Studio solution able to build both 32 bit and 64 bit binaries for GLFW2/3. Transcc has been modified to use this feature. Open a GLFW Visual Studio solution to see what I did.

There is a known problem with TDM MINGW 5.1.0 involving the use of Visual Studio style .LIB files. As these type of files are used for linking OpenAL in the desktop target, you will have problems unless you remove/rename or relocate them and include the relivant OpenAL dynamic link libraries in their place. I do have one or two ideas on having to get round this problem, but it would involve a rethink having third part libaries within the targets template directory.
 
If you download the non git files; then I have included some prebuilt binaries with that should all be in sync, but if you have problems with them. Then I suggest that you rebuild them for yourself.
Note Linux binaries are built on Linux Mint 17.2 x86_64 with Ted against the repositories version of Qt5.
Windows and OS X version of Ted are builts against Qt.5.5.1.
Windows version of transcc with TDM MinGW64 with -m32 switch
OS X version of transcc and Ted with Xcode 7.2 tools.


PLEASE READ: MOD_README.TXT for more.
