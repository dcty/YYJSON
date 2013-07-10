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

#ifndef JSONLITE_TOKEN_POOL_H
#define JSONLITE_TOKEN_POOL_H

#include "jsonlite_token.h"

#ifdef __cplusplus
extern "C" {
#endif
    
typedef void (*jsonlite_token_pool_release_value_fn)(void *);
typedef struct content_pool_size* jsonlite_token_pool;
    
typedef struct jsonlite_token_bucket {
    ptrdiff_t hash;
    const uint8_t *start;
    const uint8_t *end;
    const void *value;
    ptrdiff_t value_hash;
} jsonlite_token_bucket;
    
jsonlite_token_pool jsonlite_token_pool_create(jsonlite_token_pool_release_value_fn release_fn);
void jsonlite_token_pool_copy_tokens(jsonlite_token_pool pool);
void jsonlite_token_pool_release(jsonlite_token_pool pool);
jsonlite_token_bucket* jsonlite_token_pool_get_bucket(jsonlite_token_pool pool, jsonlite_token *token);

#ifdef __cplusplus
}
#endif

#endif
