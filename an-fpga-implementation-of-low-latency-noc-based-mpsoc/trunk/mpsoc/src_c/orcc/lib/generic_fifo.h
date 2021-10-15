/*
 * Copyright (c) 2009-2014, IETR/INSA of Rennes
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *   * Neither the name of the IETR/INSA of Rennes nor the names of its
 *     contributors may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/**
 * Ring-buffer FIFO structure
 * Lock-free and cache-efficient implementation
 * Supports 1 producer - N consumers
 */

#define UNUSED_VAR     __attribute__ ((unused))

typedef struct {
    volatile char padding0[CACHELINE_SIZE]; /** Memory padding */
    unsigned int* read_inds;                /** Current reading positions */
    volatile char padding1[CACHELINE_SIZE]; /** Memory padding */
    unsigned int write_ind;                 /** Current writing position */
    volatile char padding2[CACHELINE_SIZE]; /** Memory padding */
    T *contents;                            /** Buffer containing the FIFO's elements */
} FIFO_T(T);

UNUSED_VAR static int FIFO_GET_NUM_TOKENS(T)(FIFO_T(T) *fifo, int reader_id) {
    return fifo->write_ind - fifo->read_inds[reader_id];
}

UNUSED_VAR static int FIFO_GET_ROOM(T)(FIFO_T(T) *fifo, int nb_readers, int size) {
    int i;
    int num_tokens, max_num_tokens = 0;

   for (i = 0; i < nb_readers; i++) {
        num_tokens = fifo->write_ind - fifo->read_inds[i];
        max_num_tokens = max_num_tokens > num_tokens ? max_num_tokens : num_tokens;
    }

    return size - max_num_tokens;
}

