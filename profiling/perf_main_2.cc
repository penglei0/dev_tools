// write hello world
#include <chrono>
#include <iostream>
#include <thread>

int main(int argc, char** argv) {
  std::cout << "Hello world!\n";
  while (true) {
    // do nothing
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
  }
  return 0;
}