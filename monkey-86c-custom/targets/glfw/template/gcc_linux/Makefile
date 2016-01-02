# LINUX GLFW2
CC=gcc
CFLAGS=

CXX=g++
CXXFLAGS=

CPPFLAGS=$(CCOPTS) \
-Wno-deprecated-declarations \
-Wno-free-nonheap-object \
-Wno-unused-result \
-I../glfw/include \
-I../glfw/lib \
-I../glfw/lib/x11 \
-I../openal/include -I../stb \
-D_GLFW_HAS_GLXGETPROCADDRESS \
-D_GLFW_USE_LINUX_JOYSTICKS \
-pthread

LD=g++
LDFLAGS=$(LDOPTS)
LDLIBS=-lGL -lopenal -lX11 -lpthread $(LDLIBOPTS)

vpath %.c ../glfw/lib
vpath %.c ../glfw/lib/x11
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
x11_enable.o \
x11_fullscreen.o \
x11_glext.o \
x11_init.o \
x11_joystick.o \
x11_thread.o \
x11_time.o \
x11_window.o \
x11_keysym2unicode.o \
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
