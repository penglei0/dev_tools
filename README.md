# dev_tools

## Profiling 

```bash
cd profiling
# build
cmake . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build -j

# run perf
./tools/perf_record.sh build/

# flamegraph generated in perf_results
```

## Code coverage

Tool: https://github.com/gcovr/gcovr

```bash
gcovr -r ../ .  --gcov-ignore-parse-errors --exclude-noncode-lines --exclude-unreachable-branches --exclude-throw-branches --gcov-ignore-errors=all \
                --html-details=yes \
                --html=coverage/index.html
```
