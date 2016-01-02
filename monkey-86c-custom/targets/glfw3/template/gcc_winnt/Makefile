# WINNT GLFW3 with cross compile option

# Dawlane cross compiler alterations
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
-I../glfw3/include \
-I../glfw3/src \
-I../openal/include \
-I../stb \
-I../zlib-1.2.8 \
-I../lpng1610

# Add the addition paths if cross compiling
ifdef CROSSCOMPILE
	CPPFLAGS+= $(MINGW_INC)
endif

LDFLAGS=-Wl,--subsystem,windows $(MINGW_LIB) $(LDOPTS)
LDLIBS=-lcomdlg32 -lgdi32 -lopengl32 -lOpenAL32 -lws2_32 $(LDLIBOPTS)

vpath %.c ../glfw3/src
vpath %.c ../stb
vpath %.cpp ..

OBJS0=\
context.o \
init.o \
input.o \
monitor.o \
wgl_context.o \
win32_init.o \
win32_monitor.o \
win32_time.o \
win32_tls.o \
win32_window.o \
window.o \
winmm_joystick.o \
stb_vorbis.o \
stb_image.o \
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
