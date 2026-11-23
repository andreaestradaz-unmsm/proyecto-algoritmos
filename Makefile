# =============================================================================
# Makefile - Proyecto 2: Reproductor de Música con Listas de Reproducción
# Curso: Algoritmos y Estructuras de Datos (CC0401) - UNMSM
# =============================================================================

CXX      := g++
CXXFLAGS := -std=c++17 -Wall -Wextra -Wno-unused-parameter -pedantic -g

TARGET   := reproductor

AUDIO_SRCS := motor_audio.cpp extractor_metadata.cpp
TADS_SRCS  := cancion.cpp lista_simple.cpp lista_doble_circular.cpp reproduccion.cpp $(AUDIO_SRCS)
SRCS       := main.cpp cancion.cpp lista_simple.cpp lista_doble_circular.cpp reproduccion.cpp ui.cpp $(AUDIO_SRCS)
OBJS       := $(SRCS:.cpp=.o)

BRIDGE_SRCS := bridge_ffi.cpp $(TADS_SRCS)

ifeq ($(OS),Windows_NT)
	BRIDGE_LIB := eda_music_bridge.dll
	BRIDGE_LDFLAGS := -shared -static-libgcc -static-libstdc++
	BRIDGE_CXXFLAGS := $(CXXFLAGS) -DBRIDGE_EXPORTS
	TEST_BIN := pruebas.exe
	TEST_BRIDGE_BIN := pruebas_bridge.exe
	TEST_E1_BIN := pruebas_estudiante1.exe
	RUN_PREFIX := .\\
else
	BRIDGE_LIB := libeda_music_bridge.so
	BRIDGE_LDFLAGS := -shared
	BRIDGE_CXXFLAGS := $(CXXFLAGS) -fPIC -DBRIDGE_EXPORTS
	TEST_BIN := pruebas
	TEST_BRIDGE_BIN := pruebas_bridge
	TEST_E1_BIN := pruebas_estudiante1
	RUN_PREFIX := ./
endif

.PHONY: all clean run bridge test test-bridge test-e1 test-all

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

# Suite de pruebas de Audio, Metadatos y Cancion Extendida (Estudiante 1)
test-e1: $(TEST_E1_BIN)
	$(RUN_PREFIX)$(TEST_E1_BIN)

$(TEST_E1_BIN): pruebas_estudiante1.cpp $(TADS_SRCS)
	$(CXX) $(CXXFLAGS) pruebas_estudiante1.cpp $(TADS_SRCS) -o $(TEST_E1_BIN)

# Ejecuta todas las suites de prueba
test-all: test test-bridge test-e1

# Dependencias de cabeceras
main.o: main.cpp cancion.h lista_simple.h lista_doble_circular.h reproduccion.h ui.h motor_audio.h extractor_metadata.h
cancion.o: cancion.cpp cancion.h
lista_simple.o: lista_simple.cpp lista_simple.h cancion.h
lista_doble_circular.o: lista_doble_circular.cpp lista_doble_circular.h cancion.h
reproduccion.o: reproduccion.cpp reproduccion.h lista_doble_circular.h lista_simple.h cancion.h
ui.o: ui.cpp ui.h cancion.h lista_simple.h lista_doble_circular.h reproduccion.h
motor_audio.o: motor_audio.cpp motor_audio.h miniaudio.h cancion.h lista_doble_circular.h
extractor_metadata.o: extractor_metadata.cpp extractor_metadata.h miniaudio.h
bridge_ffi.o: bridge_ffi.cpp bridge_ffi.h cancion.h lista_simple.h lista_doble_circular.h reproduccion.h motor_audio.h extractor_metadata.h

run: $(TARGET)
	./$(TARGET)

clean:
ifeq ($(OS),Windows_NT)
	-del /Q $(OBJS) bridge_ffi.o $(TARGET).exe $(BRIDGE_LIB) $(TEST_BIN) $(TEST_BRIDGE_BIN) $(TEST_E1_BIN) 2>nul
else
	rm -f $(OBJS) bridge_ffi.o $(TARGET) $(BRIDGE_LIB) $(TEST_BIN) $(TEST_BRIDGE_BIN) $(TEST_E1_BIN)
endif
