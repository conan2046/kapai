NAME = kp_match
LINK = g++
CC  = gcc

VPATH = src/

CCFLAGS += -g
CCFLAGS += -Wall
CCFLAGS += -isystem/usr/local/include/boost-1_55/
CCFLAGS += -isystem/usr/local/gyu/include

LINKOPTS += -L/usr/local/gyu/lib/

LINKOPTS += -lgyu


TINYXML_FILES = $(notdir $(wildcard src/tinyxml/*.cpp))

CPPFILES = $(notdir $(wildcard src/*.cpp))

$(NAME):$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(TINYXML_FILES:.cpp=.o)
	$(LINK) -o $(NAME) $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(TINYXML_FILES:.cpp=.o) $(LINKOPTS)

.cpp.o:
	$(CC) -c $< $(CCFLAGS)
	
.c.o:
	$(CC) -c $< $(CFLAGS)
	
clean:
	rm -f *.o

