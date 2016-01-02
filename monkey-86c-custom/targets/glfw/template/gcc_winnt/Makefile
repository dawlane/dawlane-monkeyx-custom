# WINNT GLFW2 with cross compile option

# Dawlane cross compile changes
ifdef CROSSCOMPILE
	# Common. Set the cross compiler tool chain
	MINGW_CC=-gcc
	MINGW_CXX=-g++
	CC=$(MINGW)$(MINGW_CC)
	CFLAGS=
	CXX=$(MINGW)$(MINGW_CXX)
	CXXFLAGS=
	LD=$(MINGW)$(MINGW_CXX)
	
	# The next bits add the additional path to search
	# If MACOS is the host
	ifdef MACOS
		MINGW_INC=-I$(MINGW_PATH)/include \
		-I$(MINGW_PATH)/$(MINGW)/include

		MINGW_LIB=-L$(MINGW_PATH)/lib \
		-L$(MINGW_PATH)/$(MINGW)/lib \
		-L$(MINGW_PATH)/bin \
		-L$(MINGW_PATH)/$(MINGW)/bin
	else
	# If Linux is the host
		MINGW_INC=-I/usr/$(MINGW)/include \
		-I/usr/local/$(MINGW)/include \
		-I/usr/$(MINGW)/sys-root/mingw/include \
		-I/usr/$(MINGW)/sys-root/$(MINGW)/include

		MINGW_LIB=-L/usr/$(MINGW)/lib \
		-L/usr/local/$(MINGW)/lib \
		-L/usr/local/$(MINGW)/bin \
		-L/usr/$(MINGW)/sys-root/mingw/lib \
		-L/usr/$(MINGW)/sys-root/$(MINGW)/lib
	endif
else
	# Normal Windows MinGW toot chain
	CC=gcc
	CFLAGS=
	CXX=g++
	CXXFLAGS=
	LD=g++
	MINGW_LIB=-L../openal/libs/Win32 -L../openal/libs/Win64
endif

CPPFLAGS=$(CCOPTS) \
-Wno-free-nonheap-object \
-I../glfw/include \
-I../glfw/lib \
-I../glfw/lib/win32 \
-I../openal/include \
-I../stb

# Add the addition paths if cross compiling
ifdef CROSSCOMPILE
	CPPFLAGS+= $(MINGW_INC)
endif

LDFLAGS=-Wl,--subsystem,windows $(MINGW_LIB) $(LDOPTS)
LDLIBS=-lgdi32 -lopengl32 -lOpenAL32 -lws2_32 $(LDLIBOPTS)

vpath %.c ../glfw/lib
vpath %.c ../glfw/lib/win32
vpath %.c ../stb
vpath %.cpp ..


OBJS0=\
enable.o \
fullscreen.o \
glext.o \
image.o \
init.o \
input.o \
joystick.o \
stream.o \
tga.o \
thread.o \
time.o \
window.o \
win32_dllmain.o \
win32_enable.o \
win32_fullscreen.o \
win32_glext.o \
win32_init.o \
win32_joystick.o \
win32_thread.o \
win32_time.o \
win32_window.o \
stb_image.o \
stb_vorbis.o \
main.o

TMP=build/$(dir $(OUT))

OBJS=$(patsubst %.o,$(TMP)%.o,$(OBJS0))

all : $(OUT)

$(OUT) : $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS) $(LDLIBS)

$(TMP)%.o : %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(TMP)%.o : %.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<
	
