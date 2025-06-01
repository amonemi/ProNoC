#ifndef HISTOGRAM_H
    #define HISTOGRAM_H
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    int id;     // Histogram ID
    int value;  // Histogram value
    int* count; // Pointer to count
} Entry;

Entry* histogram = NULL;
size_t histogram_size = 0;
size_t histogram_capacity = 0;

void record(int id,int number) {
    // Search for the number
    for (size_t i = 0; i < histogram_size; i++) {
        if (histogram[i].value == number && histogram[i].id == id) {
            (*(histogram[i].count)) += 1;
            return;
        }
    }

    // Not found — add a new entry
    if (histogram_size == histogram_capacity) {
        histogram_capacity = histogram_capacity == 0 ? 8 : histogram_capacity * 2;
        histogram = (Entry*) realloc(histogram, histogram_capacity * sizeof(Entry));
        if (!histogram) {
            perror("realloc failed");
            exit(1);
        }
    }
    histogram[histogram_size].id = id;
    histogram[histogram_size].value = number;
    histogram[histogram_size].count = (int*) malloc(sizeof(int));
    if (!histogram[histogram_size].count) {
        perror("malloc failed");
        exit(1);
    }
    *(histogram[histogram_size].count) = 1;
    histogram_size++;
}

int compare_entries(const void* a, const void* b) {
    const Entry* ea = (const Entry*)a;
    const Entry* eb = (const Entry*)b;
    return (ea->value - eb->value);
}

void print_histogram(int id, const char* title1, const char* title2) {
    // Count how many entries match the histogram ID
    size_t count = 0;
    for (size_t i = 0; i < histogram_size; i++) {
        if (histogram[i].id == id) {
            count++;
        }
    }

    if (count == 0) {
        printf("Histogram ID %d not found.\n", id);
        return;
    }

    // Copy matching entries into a temporary array
    Entry* temp = (Entry*) malloc(count * sizeof(Entry));
    if (!temp) {
        perror("malloc failed");
        exit(1);
    }

    size_t idx = 0;
    for (size_t i = 0; i < histogram_size; i++) {
        if (histogram[i].id == id) {
            temp[idx++] = histogram[i];
        }
    }

    // Sort the array by value
    qsort(temp, count, sizeof(Entry), compare_entries);

    // Print header
    printf("%s", title1);
    for (size_t i = 0; i < count; i++) {
        printf("%d,", temp[i].value);
    }

    // Print counts
    printf("%s", title2);
    for (size_t i = 0; i < count; i++) {
        printf("%d,", *(temp[i].count));
    }

    free(temp);
}

void cleanup_histogram() {
    for (size_t i = 0; i < histogram_size; i++) {
        free(histogram[i].count);
    }
    free(histogram);
    histogram = NULL;
    histogram_size = 0;
    histogram_capacity = 0;
}



#endif // HISTOGRAM_H
