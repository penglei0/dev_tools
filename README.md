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