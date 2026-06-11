CXX = g++
CXXFLAGS = -Wall -Wextra -std=c++17 -O2
TARGET = php_installer
OBJS = main.o installer.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(OBJS)

%.o: %.cpp installer.hpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f *.o $(TARGET) *.exe
