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

#ifndef JSONLITE_BUILDER_H
#define JSONLITE_BUILDER_H

#include <stdio.h>
#include "jsonlite_types.h"

#ifdef __cplusplus
extern "C" {
#endif
    
    struct jsonlite_builder_struct;
    typedef struct jsonlite_builder_struct* jsonlite_builder;

    /** @brief Creates and initializes new instance of builder object.
     *
     * You should release jsonlite_builder object using ::jsonlite_builder_release.
     * @see jsonlite_builder
     * @see jsonlite_builder_release
     * @param depth the builder depth
     * @return jsonlite_builder object
     */
    jsonlite_builder jsonlite_builder_init(size_t depth);
    
    /** \brief Releases builder object.
     *
     * If builder is NULL, jsonlite_builder_release does nothing.
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @return jsonlite_result_invalid_argument when builder is NULL; otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_release(jsonlite_builder builder);
       
    /** \brief Sets beautify indentation. Default is 0.
     *
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @param indentation the beautify indentation; 0 - disabled
     * @return jsonlite_result_invalid_argument when builder is NULL; otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_set_indentation(jsonlite_builder builder, size_t indentation);
    
    /** \brief Sets format for double values. Default is "%.16g".
     *
     * jsonlite_builder_set_double_format copies format parameter and you can safety release it.
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @param format the double format; see sprintf function for details
     * @return jsonlite_result_invalid_argument when builder or format are NULL; otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_set_double_format(jsonlite_builder builder, const char *format);
    
    /** \brief Begin JSON object.
     *
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @return jsonlite_result_invalid_argument when builder is NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_object_begin(jsonlite_builder builder);
    
    /** \brief End JSON object.
     *
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @return jsonlite_result_invalid_argument when builder is NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_object_end(jsonlite_builder builder);
    
    /** \brief Begin JSON array.
     *
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @return jsonlite_result_invalid_argument when builder is NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_array_begin(jsonlite_builder builder);
    
    /** \brief End JSON array.
     *
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @return jsonlite_result_invalid_argument when builder is NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_array_end(jsonlite_builder builder);
    
    /** \brief Write JSON key.
     *
     * jsonlite_builder_key performs two-character sequence escape for 
     * U+0022, U+005C, U+002F, U+0008, U+000C, U+000A, U+000D and U+0009
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @param data the UTF-8 encoded string
     * @param length the string length
     * @return jsonlite_result_invalid_argument when builder or data are NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_key(jsonlite_builder builder, const char *data, size_t length);
    
    /** \brief Write string value.
     *
     * jsonlite_builder_key performs two-character sequence escape for
     * U+0022, U+005C, U+002F, U+0008, U+000C, U+000A, U+000D and U+0009
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @param data the UTF-8 encoded string
     * @param length the string length
     * @return jsonlite_result_invalid_argument when builder or data are NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_string(jsonlite_builder builder, const char *data, size_t length);
    
    /** \brief Write integer value.
     *
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @param value the integer value
     * @return jsonlite_result_invalid_argument when builder is NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_int(jsonlite_builder builder, long long value);
    
    /** \brief Write double value.
     *
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @param value the double value
     * @return jsonlite_result_invalid_argument when builder is NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_double(jsonlite_builder builder, double value);
    
    /** \brief Write true value.
     *
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @return jsonlite_result_invalid_argument when builder is NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_true(jsonlite_builder builder);
    
    /** \brief Write false value.
     *
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @return jsonlite_result_invalid_argument when builder is NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_false(jsonlite_builder builder);
    
    /** \brief Write null value.
     *
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @return jsonlite_result_invalid_argument when builder is NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_null(jsonlite_builder builder);
    
    /** \brief Write raw key.
     *
     * jsonlite_builder_raw_key does not perform any transformation.
     * jsonlite_builder_raw_key wraps raw key with '"' (U+0022).
     * If data already was wrapped with '"' use following practice jsonlite_builder_raw_key(d, data + 1, size - 2);
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @param data the raw data
     * @param length the data length
     * @return jsonlite_result_invalid_argument when builder or data are NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_raw_key(jsonlite_builder builder, const void *data, size_t length);
    
    /** \brief Write raw string.
     *
     * jsonlite_builder_raw_string does not perform any transformation.
     * jsonlite_builder_raw_string wraps raw string with '"' (U+0022).
     * If data already was wrapped with '"' use following practice jsonlite_builder_raw_string(d, data + 1, size - 2);
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @param data the raw data
     * @param length the data length
     * @return jsonlite_result_invalid_argument when builder or data are NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_raw_string(jsonlite_builder builder, const void *data, size_t length);
    
    /** \brief Write raw value.
     *
     * jsonlite_builder_raw_value does not perform any transformation.
     * jsonlite_builder_raw_value does not wrap raw value with '"' (U+0022).
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @param data the raw data
     * @param length the data length
     * @return jsonlite_result_invalid_argument when builder or data are NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_raw_value(jsonlite_builder builder, const void *data, size_t length);
    
    /** \brief Gets buffer data.
     *
     * You are responsible to free buffer using free function.
     * @see jsonlite_builder
     * @see jsonlite_result
     * @param builder the builder object
     * @param[out] buffer the output buffer
     * @param[out] size the buffer size
     * @return jsonlite_result_invalid_argument when builder, buffer or size are NULL;
     * jsonlite_result_not_allowed when operation is not allowed;
     * otherwise jsonlite_result_ok.
     */
    jsonlite_result jsonlite_builder_data(jsonlite_builder builder, char **buffer, size_t *size);

#ifdef __cplusplus
}
#endif

#endif
