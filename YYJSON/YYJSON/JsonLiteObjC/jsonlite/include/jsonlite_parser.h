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

#ifndef JSONLITE_PARSER_H
#define JSONLITE_PARSER_H

#include <stdio.h>
#include <stddef.h>
#include <stdint.h>
#include "jsonlite_token.h"
#include "jsonlite_types.h"

#ifdef __cplusplus
extern "C" {
#endif
    
    struct jsonlite_parser_struct;
    typedef struct jsonlite_parser_struct* jsonlite_parser;
    
    /** @brief Contains callback information.
     */
    typedef struct {
        /** @brief jsonlite parser object that initiate callback.
         * @note
         * You can use ::jsonlite_parser_suspend to stop tokenization.
         */
        jsonlite_parser parser;
        
        /** @brief Reserved for client usage.
         */
        void *client_state;
    } jsonlite_callback_context;
    
    /** @brief Type of value callback function.
     */
    typedef void (*jsonlite_value_callback)(jsonlite_callback_context *, jsonlite_token *);
    
    /** @brief Type of state callback function.
     */
    typedef void (*jsonlite_state_callback)(jsonlite_callback_context *);
    
    /** @brief Contains references to client callback functions.
     * 
     * You can use the global jsonlite_default_callbacks constant to initialize default values.
     */
    typedef struct {
        /** @brief Called when parser finished tokenization.
         * You can retrieve result of parsing using jsonlite_parser_get_result.
         */
        jsonlite_state_callback parse_finished;
        
        /** @brief Called when parser found object start.
         */
        jsonlite_state_callback object_start;
        
        /** @brief Called when parser found object end.
         */
        jsonlite_state_callback object_end;
        
        /** @brief Called when parser found array start.
         */
        jsonlite_state_callback array_start;
        
        /** @brief Called when parser found array end.
         */
        jsonlite_state_callback array_end;
        
        /** @brief Called when parser found \a true token.
         */
        jsonlite_state_callback true_found;
        
        /** @brief Called when parser found \a false token.
         */
        jsonlite_state_callback false_found;
        
        /** @brief Called when parser found \a null token.
         */
        jsonlite_state_callback null_found;
        
        /** @brief Called when parser found key token.
         */
        jsonlite_value_callback key_found;
        
        /** @brief Called when parser found string token.
         */
        jsonlite_value_callback string_found;
        
        /** @brief Called when parser found number token.
         */
        jsonlite_value_callback number_found;
        
        /** @brief Callbacks' context, will be past as first parameter of callback function.
         */
        jsonlite_callback_context context;
    } jsonlite_parser_callbacks;

    /** @brief Estimates memory usage.
     * @note
     * This value depends on CPU architectures.
     * @param depth the parsing depth.
     * @return Estimated size in bytes.
     */
    size_t jsonlite_parser_estimate_size(size_t depth);

    /** @brief Creates and initializes new instance of parser object.
     *
     * You should release jsonlite_parser object using ::jsonlite_parser_release.
     * @see jsonlite_parser
     * @see jsonlite_parser_release
     * @param depth the parsing depth.
     * @return jsonlite_parser object.
     */
    jsonlite_parser jsonlite_parser_init(size_t depth);
    
    /** \brief Copies provided callbacks structure to parser object.
     * @see jsonlite_parser
     * @see jsonlite_parser_callbacks
     * @see jsonlite_result
     * @param parser the parser object.
     * @param parser the callbacks object.
     * @return jsonlite_result_invalid_argument when parser or cbs are NULL; otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_parser_set_callback(jsonlite_parser parser, const jsonlite_parser_callbacks *cbs);
    
    /** \brief Returns result of last operation.
     * @see jsonlite_parser
     * @see jsonlite_result
     * @param parser the parser object.
     * @return jsonlite_result_invalid_argument when parser is NULL; otherwise s result of last operation.
     */
    jsonlite_result jsonlite_parser_get_result(jsonlite_parser parser);
    
    /** \brief Performs JSON tokenization.
     *
     * jsonlite is a chunk parser and you can use this function to parser a fragment of JSON.
     * @see jsonlite_parser
     * @see jsonlite_result
     * @param parser the parser object.
     * @param buffer the pointer to JSON payload buffer.
     * @param size the JSON payload buffer size.
     * @return JSON parsing result or jsonlite_result_invalid_argument when some parameter is invalid.
     * 
     * There is an example of JSON validation
     * @code{.c}
     * char json[] = "{\"key\" : 12345, \"obj\": {}, \"array\":[null, true, false, \"string\"]}";
     * jsonlite_parser p = jsonlite_parser_init(16);
     * jsonlite_result result = jsonlite_parser_tokenize(p, json, sizeof(json));
     * assert(result == jsonlite_result_ok);
     * jsonlite_parser_release(p);
     * @endcode
     *
     * There is an another example of JSON chunk parsing.
     * @code{.c}
     * char chunk1[] = "{\"key\" : 12345, \"obj\": {}, \"arr";
     * char chunk2[] = "ay\":[null, true, false, \"string\"]}";
     * jsonlite_parser p = jsonlite_parser_init(16);
     *
     * jsonlite_result result = jsonlite_parser_tokenize(p, chunk1, sizeof(chunk1) - 1);
     * assert(result == jsonlite_result_end_of_stream);
     * // Now you can release or reuse chunk1 buffer.
     *
     * result = jsonlite_parser_tokenize(p, chunk2, sizeof(chunk2) - 1);
     * assert(result == jsonlite_result_ok);
     *
     * jsonlite_parser_release(p);
     * @endcode
     */
    jsonlite_result jsonlite_parser_tokenize(jsonlite_parser parser, const void *buffer, size_t size);
    
    /** \brief Resumes JSON tokenization.
     * @see jsonlite_parser
     * @see jsonlite_result
     * @param parser the parser object.
     * @return JSON parsing result or jsonlite_result_invalid_argument when parser is NULL.
     */
    jsonlite_result jsonlite_parser_resume(jsonlite_parser parser);
    
    /** \brief Suspends JSON tokenization.
     *
     * You can continue tokenization later by calling ::jsonlite_parser_resume.
     * @see jsonlite_parser
     * @see jsonlite_result
     * @param parser the parser object.
     * @return jsonlite_result_invalid_argument when parser is NULL; 
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_parser_suspend(jsonlite_parser parser);
    
    /** \brief Releases parser object.
     *
     * If parser is NULL, jsonlite_parser_release does nothing.
     * @see jsonlite_parser
     * @see jsonlite_result
     * @param parser the parser object.
     */
    void jsonlite_parser_release(jsonlite_parser parser);

    /** \brief jsonlite_parser_callbacks structure initialized with callbacks that do nothing.
     */
    extern const jsonlite_parser_callbacks jsonlite_default_callbacks;
    
#ifdef __cplusplus
}
#endif

#endif
