//
//  Copyright 2012-2013, Andrii Mamchur
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License

#include "../include/jsonlite_token_pool.h"
#include <stdlib.h>
#include <string.h>

#define JSONLITE_TOKEN_POOL_FRONT 0x80
#define JSONLITE_TOKEN_POOL_FRONT_MASK (JSONLITE_TOKEN_POOL_FRONT - 1)

typedef struct content_pool_size {
    jsonlite_token_bucket *buckets[JSONLITE_TOKEN_POOL_FRONT];
    size_t buckets_length[JSONLITE_TOKEN_POOL_FRONT];
    size_t buckets_capacity[JSONLITE_TOKEN_POOL_FRONT];
    
    uint8_t *content_pool;
    size_t content_pool_size;
    
    jsonlite_token_pool_release_value_fn release_fn;
    
} jsonlite_token_pool_struct;

static void jsonlite_extend_capacity(jsonlite_token_pool pool, int index);
static int jsonlite_bucket_not_copied(jsonlite_token_pool pool, jsonlite_token_bucket *b);
static int jsonlite_token_compare(const uint8_t *t1, const uint8_t *t2, size_t length);
static uint32_t jsonlite_hash(const uint8_t *data, size_t len);

jsonlite_token_pool jsonlite_token_pool_create(jsonlite_token_pool_release_value_fn release_fn) {
    jsonlite_token_pool pool = (jsonlite_token_pool)calloc(1, sizeof(jsonlite_token_pool_struct));
    pool->release_fn = release_fn;
    return pool;
}

void jsonlite_token_pool_copy_tokens(jsonlite_token_pool pool) {
    size_t length, size = pool->content_pool_size;
    uint8_t *buffer, *p;
    ptrdiff_t offset = 0;
    jsonlite_token_bucket *b;
	int i;

    for (i = 0; i < JSONLITE_TOKEN_POOL_FRONT; i++) {
        b = pool->buckets[i];
        if (jsonlite_bucket_not_copied(pool, b)) {
            size += b->end - b->start;
        }
    }
    
    if (size == pool->content_pool_size) {
        return;
    }
    
	buffer = (uint8_t *)malloc(size);
    if (pool->content_pool != NULL) {
        offset = buffer - pool->content_pool;
        memcpy(buffer, pool->content_pool, pool->content_pool_size); // LCOV_EXCL_LINE
    }
    p = buffer + pool->content_pool_size;
    
    for (i = 0; i < JSONLITE_TOKEN_POOL_FRONT; i++) {
        b = pool->buckets[i];
        if (b == NULL) {
            continue;
        }
        
        if (jsonlite_bucket_not_copied(pool, b)) {
            length = b->end - b->start;
            memcpy(p, b->start, length); // LCOV_EXCL_LINE
            b->start = p,
            b->end = p + length,
            p += length;
        } else {
            b->start += offset;
            b->end += offset;
        }
    }
    
    free(pool->content_pool);
    pool->content_pool = buffer;
    pool->content_pool_size = size;
}

void jsonlite_token_pool_release(jsonlite_token_pool pool) {
	ptrdiff_t i, j, count;
    jsonlite_token_bucket *bucket;
    
    if (pool == NULL) {
        return;
    }

    for (i = 0; i < JSONLITE_TOKEN_POOL_FRONT; i++) {
        bucket = pool->buckets[i];
        if (bucket == NULL) {
            continue;
        }
        
        if (pool->release_fn != NULL) {
            count = pool->buckets_length[i];            
            for (j = 0; j < count; j++, bucket++) {
                pool->release_fn((void *)bucket->value);           
            }
        }

        free(pool->buckets[i]);
    }
    
    free(pool->content_pool);
    free(pool);
}

jsonlite_token_bucket* jsonlite_token_pool_get_bucket(jsonlite_token_pool pool, jsonlite_token *token) {
    size_t length, count;
    uint32_t hash, index;
    jsonlite_token_bucket *bucket;
    
    if (pool == NULL || token == NULL) {
        return NULL;
    }
    
    if (token->start == NULL || token->end == NULL) {
        return NULL;
    }
    
    length = token->end - token->start;
    hash = jsonlite_hash(token->start, length);
    index = hash & JSONLITE_TOKEN_POOL_FRONT_MASK;
    bucket = pool->buckets[index];
    count = pool->buckets_length[index];
    for (; count > 0; count--, bucket++) {
        if (bucket->hash != hash) {
            continue;
        }
        
        if (length != bucket->end - bucket->start) {
            continue;
        }
        
        if (jsonlite_token_compare(token->start, bucket->start, length)) {
            return bucket;
        }
    }

    if (pool->buckets_length[index] >= pool->buckets_capacity[index]) {
        jsonlite_extend_capacity(pool, index);
    }
    
    bucket = pool->buckets[index] + pool->buckets_length[index]++;
    bucket->hash = hash;
    bucket->start = token->start;
    bucket->end = token->end;
    bucket->value = NULL;
    return bucket;
}

static int jsonlite_token_compare(const uint8_t *t1, const uint8_t *t2, size_t length) {
    return memcmp(t1, t2, length) == 0 ? 1 : 0;
}

static void jsonlite_extend_capacity(jsonlite_token_pool pool, int index) {
    jsonlite_token_bucket *b, *extended;
    size_t capacity, size;
    
    capacity = pool->buckets_capacity[index];
    if (capacity == 0) {
        capacity = 0x10;
    }
    
    size = capacity * sizeof(jsonlite_token_bucket);
    b = pool->buckets[index];
	extended = (jsonlite_token_bucket *)malloc(2 * size);
    
    if (b != NULL) {
        memcpy(extended, b, size); // LCOV_EXCL_LINE
        free(b);
    }
    
    pool->buckets[index] = extended;
    pool->buckets_capacity[index] = 2 * capacity;
}

static int jsonlite_bucket_not_copied(jsonlite_token_pool pool, jsonlite_token_bucket *b) {
    if (b == NULL) {
        return 0;
    }
    
    int res = b->start < pool->content_pool;
    res |= b->start >= pool->content_pool + pool->content_pool_size;
    return res;
}

// Used MurmurHash2 function by Austin Appleby
// http://code.google.com/p/smhasher/ revision 147

//-----------------------------------------------------------------------------
// MurmurHash2 was written by Austin Appleby, and is placed in the public
// domain. The author hereby disclaims copyright to this source code.

// Note - This code makes a few assumptions about how your machine behaves -

// 1. We can read a 4-byte value from any address without crashing
// 2. sizeof(int) == 4

// And it has a few limitations -

// 1. It will not work incrementally.
// 2. It will not produce the same results on little-endian and big-endian
//    machines.

static uint32_t MurmurHash2 ( const void * key, int len, uint32_t seed )
{
    // 'm' and 'r' are mixing constants generated offline.
    // They're not really 'magic', they just happen to work well.
    
    const uint32_t m = 0x5bd1e995;
    const int r = 24;
    
    // Initialize the hash to a 'random' value
    
    uint32_t h = seed ^ len;
    
    // Mix 4 bytes at a time into the hash
    
    const unsigned char * data = (const unsigned char *)key;
    
    while(len >= 4)
    {
        uint32_t k = *(uint32_t*)data;
        
        k *= m;
        k ^= k >> r;
        k *= m;
        
        h *= m;
        h ^= k;
        
        data += 4;
        len -= 4;
    }
    
    // Handle the last few bytes of the input array
    
    switch(len)
    {
        case 3: h ^= data[2] << 16;
        case 2: h ^= data[1] << 8;
        case 1: h ^= data[0];
            h *= m;
    };
    
    // Do a few final mixes of the hash to ensure the last few
    // bytes are well-incorporated.
    
    h ^= h >> 13;
    h *= m;
    h ^= h >> 15;
    
    return h;
}

//-----------------------------------------------------------------------------

static uint32_t jsonlite_hash(const uint8_t *data, size_t len) {
    return MurmurHash2(data, (int)len, 0);
}
