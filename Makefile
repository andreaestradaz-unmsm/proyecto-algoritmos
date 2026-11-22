# =============================================================================
# Makefile - Proyecto 2: Reproductor de Música con Listas de Reproducción
# Curso: Algoritmos y Estructuras de Datos (CC0401) - UNMSM
# =============================================================================

CXX      := g++
CXXFLAGS := -std=c++17 -Wall -Wextra -Wno-unused-parameter -pedantic -g

TARGET   := reproductor

SRCS := main.cpp cancion.cpp lista_simple.cpp lista_doble_circular.cpp reproduccion.cpp ui.cpp
OBJS := $(SRCS:.cpp=.o)

TADS_SRCS := cancion.cpp lista_simple.cpp lista_doble_circular.cpp reproduccion.cpp
BRIDGE_SRCS := bridge_ffi.cpp $(TADS_SRCS)

ifeq ($(OS),Windows_NT)
	BRIDGE_LIB := eda_music_bridge.dll
	BRIDGE_LDFLAGS := -shared -static-libgcc -static-libstdc++
	BRIDGE_CXXFLAGS := $(CXXFLAGS) -DBRIDGE_EXPORTS
	TEST_BIN := pruebas.exe
	TEST_BRIDGE_BIN := pruebas_bridge.exe
	RUN_PREFIX := .\\
else
	BRIDGE_LIB := libeda_music_bridge.so
	BRIDGE_LDFLAGS := -shared
	BRIDGE_CXXFLAGS := $(CXXFLAGS) -fPIC -DBRIDGE_EXPORTS
	TEST_BIN := pruebas
	TEST_BRIDGE_BIN := pruebas_bridge
	RUN_PREFIX := ./
endif

.PHONY: all clean run bridge test test-bridge

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(OBJS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Biblioteca compartida para Dart FFI (Estudiante 2 -> Estudiante 3)
bridge: $(BRIDGE_LIB)

$(BRIDGE_LIB): $(BRIDGE_SRCS) bridge_ffi.h
	$(CXX) $(BRIDGE_CXXFLAGS) $(BRIDGE_SRCS) -o $(BRIDGE_LIB) $(BRIDGE_LDFLAGS)

# Suite de pruebas de los TADs del equipo
test: $(TEST_BIN)
	$(RUN_PREFIX)$(TEST_BIN)

$(TEST_BIN): pruebas.cpp $(TADS_SRCS) ui.cpp
	$(CXX) $(CXXFLAGS) pruebas.cpp $(TADS_SRCS) ui.cpp -o $(TEST_BIN)

# Suite de pruebas del puente FFI/JSON (Estudiante 2)
test-bridge: $(TEST_BRIDGE_BIN)
	$(RUN_PREFIX)$(TEST_BRIDGE_BIN)

$(TEST_BRIDGE_BIN): pruebas_bridge.cpp $(BRIDGE_SRCS) bridge_ffi.h
	$(CXX) $(CXXFLAGS) pruebas_bridge.cpp $(BRIDGE_SRCS) -o $(TEST_BRIDGE_BIN)

# Dependencias de cabeceras
main.o: main.cpp cancion.h lista_simple.h lista_doble_circular.h reproduccion.h ui.h
cancion.o: cancion.cpp cancion.h
lista_simple.o: lista_simple.cpp lista_simple.h cancion.h
lista_doble_circular.o: lista_doble_circular.cpp lista_doble_circular.h cancion.h
reproduccion.o: reproduccion.cpp reproduccion.h lista_doble_circular.h lista_simple.h cancion.h
ui.o: ui.cpp ui.h cancion.h lista_simple.h lista_doble_circular.h reproduccion.h
bridge_ffi.o: bridge_ffi.cpp bridge_ffi.h cancion.h lista_simple.h lista_doble_circular.h reproduccion.h

run: $(TARGET)
	./$(TARGET)

clean:
ifeq ($(OS),Windows_NT)
	-del /Q $(OBJS) bridge_ffi.o $(TARGET).exe $(BRIDGE_LIB) $(TEST_BIN) $(TEST_BRIDGE_BIN) 2>nul
else
	rm -f $(OBJS) bridge_ffi.o $(TARGET) $(BRIDGE_LIB) $(TEST_BIN) $(TEST_BRIDGE_BIN)
endif
