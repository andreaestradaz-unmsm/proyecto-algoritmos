# =============================================================================
# Makefile - Proyecto 2: Reproductor de Música con Listas de Reproducción
# Curso: Algoritmos y Estructuras de Datos (CC0401) - UNMSM
# =============================================================================

CXX      := g++
CXXFLAGS := -std=c++17 -Wall -Wextra -Wno-unused-parameter -pedantic -g

TARGET   := reproductor

SRCS := main.cpp cancion.cpp lista_simple.cpp lista_doble_circular.cpp reproduccion.cpp ui.cpp
OBJS := $(SRCS:.cpp=.o)

.PHONY: all clean run

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(OBJS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Dependencias de cabeceras
main.o: main.cpp cancion.h lista_simple.h lista_doble_circular.h reproduccion.h ui.h
cancion.o: cancion.cpp cancion.h
lista_simple.o: lista_simple.cpp lista_simple.h cancion.h
lista_doble_circular.o: lista_doble_circular.cpp lista_doble_circular.h cancion.h
reproduccion.o: reproduccion.cpp reproduccion.h lista_doble_circular.h lista_simple.h cancion.h
ui.o: ui.cpp ui.h cancion.h lista_simple.h lista_doble_circular.h reproduccion.h

run: $(TARGET)
	./$(TARGET)

clean:
ifeq ($(OS),Windows_NT)
	-del /Q $(OBJS) $(TARGET).exe 2>nul
else
	rm -f $(OBJS) $(TARGET)
endif
