NAME = kapai
LINK = g++
CC  = gcc

VPATH = src/:src/tinyxml
VPATH += :src/gyu

CCFLAGS += -g
CCFLAGS += -Wall 
CCFLAGS += -std=c++11
#-D_DEBUG
CCFLAGS += -I/usr/local/include/boost-1_55/
CCFLAGS += -I/usr/local/gyu/include
CCFLAGS += -Isrc/tinyxml/
CCFLAGS += -Isrc/gyu/

LINKOPTS += -L/usr/local/gyu/lib/

LINKOPTS += -lmysqlclient
LINKOPTS += -llua
LINKOPTS += -lz
LINKOPTS += -lssl
LINKOPTS += -lcrypto

TINYXML_FILES = $(notdir $(wildcard src/tinyxml/*.cpp))
GYU_FILES = $(notdir $(wildcard src/gyu/*.cpp))

CPPFILES = $(notdir $(wildcard src/*.cpp))

$(NAME):$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(TINYXML_FILES:.cpp=.o) $(GYU_FILES:.cpp=.o)
	$(LINK) -o $(NAME) $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(TINYXML_FILES:.cpp=.o) $(GYU_FILES:.cpp=.o) $(LINKOPTS)

.cpp.o:
	$(CC) -c $< $(CCFLAGS)
	
.c.o:
	$(CC) -c $< $(CFLAGS)
	
clean:
	rm -f *.o

