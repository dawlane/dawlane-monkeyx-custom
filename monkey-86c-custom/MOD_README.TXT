
Unofficial modifications to v86c by dawlane

Modifications to transcc dawlane mods v0.04

#GLFW_APP_FILENAME and #CC_OUT_FILENAME will now change the final executable file name. Note that white space character are not supported and switching C++tools
with MinGW Cross compiler will leave old files intact if you change the name.

You can pass additional parameters to Visual Studio directly for the GLFW targets with #GLFW_VSTUDIO_OPTS and for XCODE use #GLFW_XCODE_OPTS.

Added a new Exectue function only for use in transcc.
	It returns text outputed to stdout and stderr, as well as a return code. To use, you must pass an empty string.
	It's primary use is to get limited information from tools and not a full output from something like g++ while it's compiling code. Trying to do that may make it crash when you run out of memory.
 
iOS Target updated to include four new config variables:
	#IOS_DEVICE_NAME		- Allows you to select a device by name.
	#IOS_SDK_VERSION		- Allows you to select an installed SDK by version. Can be used with the previous config variable to refine the target device if there is more than one with the same name.
	#IOS_BUNDLE_ID			- Allows you to change the application bundle identifier. Use only the reverse domain part for this e.g. com.yourcompany, as the following config variable will complete the rest.
	#IOS_PRODUCT_ID			- Allows you to change the name of the application bundle. Note that this will complete the previous config variable. e.g. com.yourcompany.MonkeyGame

iOS Project template updated Deployment Target to 6.0 and MonkeyGame scheme set to share. Setting it to share saves opening the project in Xcode to update it for each user.

Fixed iOS Simulator not starting.
	Note that the code for prior versions has beem removed. 
	With the new Execute function. It is now possible to query tools for information such as instruments.
	You can select which to use with #IO_DEVICE_NAME. The default is iPhone 4s.

Modifications to transcc dawlane mods v0.03

Added a quick set file permissions script for Linux

Added a transcc option (-msize=) to be able to switch between 32 bit and 64 bit building.
	Only GLFW Desktop targets will recognise this. You can override this from your source code with
	#GLFW_GCC_CC_OPTS, #GLFW_GCC_LD_OPTS and #GLFW_DESKTOP_MSIZE. You will of course require a compiler capable of compiling 32 and 64 bit binaries.

Added four compiler directives for GLFW2/3 Desktop to use with MinGW and Linux GCC.
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
