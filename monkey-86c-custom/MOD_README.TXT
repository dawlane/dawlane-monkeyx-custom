
Unofficial modifications to v86c by dawlane

Added a quick set file permissions script for Linux

Modifications to transcc dawlane mods v0.03

Added a transcc option (-msize=) to be able to switch between 32 bit and 64 bit building.
	Only GLFW Desktop targets will recognise this. You can override this from your source code with
	#GLFW_GCC_CC_OPTS, #GLFW_GCC_LD_OPTS and #GLFW_DESKTOP_MSIZE. You will of course require a compiler capable of compiling 32 and 64 bit binaries.

Added four compiler directives for GLFW2/3 Desktop to use with MinGW and Linux GCC.
	The first for are for advanced use, so if you do not understand GCC/MinGW options; then don't use them.
	#GLFW_GCC_CC_OPTS		- Allows you to pass GCC/MinGW compiler options directly to the backend compiler.
	#GLFW_GCC_LD_OPTS		- Allows you to pass GCC/MinGW linker options directly to the backend compiler.
	#GLFW_GCC_LDLIBS_OPTS		- Allows you to pass addition libraries and search options.
	#GLFW_DESKTOP_MSIZE		- Allows you to switch between building a 32 or 64 bit application.
					This will override any -m32/64 switchs in CC/LD or trans cc -msize options.
					Also works with Visual Studio 2013/2015 as long as the solution is created to support this.

PLEASE NOTE:
	If #GLFW_GCC_CC_OPTS and #GLFW_GCC_LD_OPTS have different -m32/-m64, then transcc stops with an error.
	If transcc -msize or GLFW_DESKTOP_MSIZE are set then such an error is ignored and compiling will continue with what ever is set. 
	Checks for exotic X86_64 options like -mx32,-m16 and -miamcu are not implemented (yet). Use of these incorrectly will cause the GCC back end to fail.
	As will any other incorretly use option.
	If no such otions are passed in DESKTOP_MSIZE/CC/LD or the -msize= option if passed to transcc. Then the native GCC/MinGW built-in options are used.
	For correct use of compiler options, see the documentaion for GCC options at https://gcc.gnu.org/onlinedocs.
	GLFW+ANGLE does not support 64 bit compilation due to the ANGLE libraies being only 32 bit.

Add the ability to use a MinGW cross compiler for Linux and OS X to target Microsoft Windows.
	You will of course have to install the cross compiler, the correct variables set in the MonkeyX config files, a Windows version of OpenAL and WINE to test with.
	To activate the cross compiling feature, pass -mingw32cross as a parameter to transcc
	Valid for GLFW 2/3 and C++ Tool.
	If there is no cross compiler pressent, then passing the option will have no affect and a normal native build will begin.
	
	A Quick explaination of cross compiler tool chains and known issues:
		Currently the latest cross compilers that I have see are based on GCC 4.8
		Toolchains files have a naming prefix of CPU-CROSS_COMIPLER_NAME e.g. i686-w64-Mingw32.
		The executable files have there name appended to the prefix e.g. x86_64-w64-MinGw32-g++
		Linux installs the toolchains in /usr/local or /usr/bin with the toolchain prefix. So only the tootchain prefix is required.
		The Mac versions are relocatable and require both a path and a toolchain prefix set.
		The i586/i686-w64 version only outputs 32 bit binaries. x86_64-w64 will create both 32 bit and 64 bit binaries, but apparently
		32 bit creation is broken in MinGW-w64 4.8. (Only tested in Linux)

Modified template Makefiles of winnt/linux and Visual Studio solutions to make use of the new features.
	Also included VS 2015 files. You will need to do a bit of renaming of the directoies in the glfw, glfw3 and glfw+angle to use them.

Added modifications to Ted to control 32/64 building and cross compiler use.

Updated Documentation to include new features.