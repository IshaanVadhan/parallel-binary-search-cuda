#include <iostream>
#include <vector>
#include <ctime>
#include <string>
#include <cmath>
#include <algorithm>

using namespace std;

struct Result {
    vector<int> arr;
    int array_size;
    int key;
    double sequential_time;
    double parallel_time;
    double speedup;
    int search_index;
};

void printResult(const Result& result) {
    cout << "{\n";
    cout << "\"result\": {\n";
    cout << "\"arr_size\": " << result.array_size << ",\n";
    cout << "\"key\": " << result.key << ",\n";
    cout << "\"arr\": [";
    for (size_t i = 0; i < result.arr.size(); ++i) {
        cout << result.arr[i];
        if (i != result.arr.size() - 1)
            cout << ", ";
    }
    cout << "],\n";
    cout << "\"seq_time\": " << result.sequential_time << ",\n";
    cout << "\"par_time\": " << result.parallel_time << ",\n";
    if (!isnan(result.speedup)) {
        cout << "\"speedup\": " << result.speedup << ",\n";
    } else {
        cout << "\"speedup\": null,\n"; // Handle NaN speedup as null
    }
    cout << "\"search_index\": " << result.search_index << "\n";
    cout << "}\n";
    cout << "}\n";
}


int binarySearchSequential(const vector<int>& arr, int key) {
    int low = 0;
    int high = arr.size() - 1;

    while (low <= high) {
        int mid = low + (high - low) / 2;
        if (arr[mid] == key)
            return mid;
        else if (arr[mid] < key)
            low = mid + 1;
        else
            high = mid - 1;
    }

    return -1; // key not found
}

__global__ void binarySearchParallel(const int* arr, int key, int* result, int size) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;

    if (tid < size) {
        if (arr[tid] == key) {
            *result = tid;
        }
    }
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        cerr << "Usage: " << argv[0] << " <array_size> <key> <array_element_1> <array_element_2> ...\n";
        return 1;
    }

    int size = stoi(argv[1]);
    int key = stoi(argv[2]);
    vector<int> arr(size);

    for (int i = 0; i < size; i++) {
        arr[i] = stoi(argv[3 + i]);
    }

    sort(arr.begin(), arr.end());

    int* d_arr, *d_result;
    cudaMalloc((void**)&d_arr, size * sizeof(int));
    cudaMalloc((void**)&d_result, sizeof(int));

    cudaMemcpy(d_arr, arr.data(), size * sizeof(int), cudaMemcpyHostToDevice);

    // Timing for parallel binary search
    clock_t start_parallel = clock();
    binarySearchParallel<<<1, size>>>(d_arr, key, d_result, size);
    cudaDeviceSynchronize();
    clock_t end_parallel = clock();
    double time_parallel = ((double)(end_parallel - start_parallel)) / CLOCKS_PER_SEC;

    int h_result;
    cudaMemcpy(&h_result, d_result, sizeof(int), cudaMemcpyDeviceToHost);

    // Timing for sequential binary search
    clock_t start_sequential = clock();
    int index_sequential = binarySearchSequential(arr, key);
    clock_t end_sequential = clock();
    double time_sequential = ((double)(end_sequential - start_sequential)) / CLOCKS_PER_SEC;

    // Calculate speedup
    double speedup = time_sequential / time_parallel;

    // Create a JSON-like object
    Result result;
    result.arr = arr;
    result.array_size = size;
    result.key = key;
    result.sequential_time = time_sequential;
    result.parallel_time = time_parallel;
    result.speedup = speedup;
    result.search_index = index_sequential != -1 ? index_sequential : h_result;

    printResult(result);

    // Free device memory
    cudaFree(d_arr);
    cudaFree(d_result);

    return 0;
}