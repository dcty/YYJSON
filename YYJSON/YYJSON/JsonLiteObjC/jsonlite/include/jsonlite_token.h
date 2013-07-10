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

#ifndef JSONLITE_TOKEN_H
#define JSONLITE_TOKEN_H

#include <stdio.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif
    struct jsonlite_token;
    struct jsonlite_parser_struct;

    /** @brief Provides the hints for number token parsing.
     * 
     * This values is valid for jsonlite_parser_callbacks::number_found callback only.
     */
    typedef enum {
        /** @brief Indicates that number token has integer part.
         * 
         * @note
         * This flag is always set because of JSON number always has integer part (value .123 is not allowed). 
         */
        jsonlite_number_int = 0x01,
        
        /** @brief Indicates that number token has fraction part.
         *
         * This flag will set if token has an fraction part. For example: 123.987;
         * in current case fraction part is .987.
         */
        jsonlite_number_frac = 0x02,
        
        /** @brief Indicates that number token has exponent part.
         *
         * This flag will set if token has an exponent part.
         *
         * For example: 
         * For integer values: 123e5, 123E5, 123E+5, 123e+5;
         * all of this numbers are equal to each other and has exponent part.
         *
         * An other case 12300000 is also equals to previous numbers but has no exponent part.
         *
         * For floating point values:  123.01e5, 123.01E5, 123.01E+5, 123.01e+5;
         * all of this number are equal to each other and has exponent part.
         * An other case 12301000 is also equals to previous numbers but has no exponent part.
         */
        jsonlite_number_exp = 0x04,
        
        /** @brief Indicates that number token has negative value.
         *
         * This flag will set if token starts with '-' character.
         */
        jsonlite_number_negative = 0x08,
        
        /** @brief Indicates that number token starts with zero character.
         */
        jsonlite_number_zero_leading = 0x10,
        \
        /** @brief Indicates that number token starts with digit that is greater 0.
         */
        jsonlite_number_digit_leading = 0x20
    } jsonlite_number_type;
    
    /** @brief Provides the hints for string token parsing.
     *
     * This values is valid for jsonlite_parser_callbacks::string_found
     * and jsonlite_parser_callbacks::key_found callbacks only.
     */
    typedef enum {
        /** @brief Indicates that string token contains ASCII characters.
         *
         * @note
         * This flag is always set because of JSON string always has ASCII characters.
         */
        jsonlite_string_ascii = 0x01,
        
        /** @brief Indicates that string token has the sequences of UTF-8 characters.
         *
         * @note
         * This flag will set if string token has 2, 3 or 4 subsequently.
         */
        jsonlite_string_utf8 = 0x02,
        
        /** @brief Indicates that string token has an escaped character(s).
         *
         * This flag will be set if string token has one or more following escaped character:
         * - \\"
         * - \\\\
         * - \\n
         * - \\r
         * - \\/
         * - \\b
         * - \\f
         * - \\t
         */
        jsonlite_string_escape = 0x04,
        
        /** @brief Indicates that string token has one or more unicode escaped character(s).
         *
         * This flag will be set if string token has \\uXXXX escape - where (XXXX is an unicode character code)
         */
        jsonlite_string_unicode_escape = 0x04
    } jsonlite_string_type;
    
    /** @brief Contains information about parsed token.
     */
    typedef struct jsonlite_token {
        /** @brief This variable is reserved for high-level libraries.
         */
        void *ext;
        
        /** @brief Contains the start position of token.
         */
        const uint8_t *start;
        
        /** @brief Contains the end position of tokens.
         *
         * End position does not below to token, it should be interpreted as position of zero character.
         * @note
         * To measure token length you can use following expression: token->end - token->start. 
         */
        const uint8_t *end;

        /** @brief Contains the hints for token parsing.
         */
        union {
            /** @brief Contains the hints for number token parsing.
             */
            jsonlite_number_type number_type;
            
            /** @brief Contains the hints for string token parsing.
             */
            jsonlite_string_type string_type;
        };
    } jsonlite_token;

    
    /** @brief Returns a size of memory that is required for token conversion to UTF-8 string.
     * @param ts jsonlite token
     * @return 0 if ts is NULL; otherwise required size of for token conversion.
     */
    size_t jsonlite_token_decode_size_for_uft8(jsonlite_token *ts);
    
    /** @brief Converts specified token to UTF-8 string.
     *
     * Function converts specified token to UTF-8 string encoding and copy zero terminated string to buffer.
     * @note
     * Function will alloc memory by itself if *buffer == NULL.
     * In this case you are responsible for memory releasing by using free() function.
     * @param ts jsonlite token
     * @return length in bytes  of converted string.
     */
    size_t jsonlite_token_decode_to_uft8(jsonlite_token *ts, uint8_t **buffer);
    
    /** @brief Returns a size of memory that is required for token conversion to UTF-16 string.
     * @param ts jsonlite token
     * @return 0  if ts is NULL; otherwise required size of for token conversion.
     */
    size_t jsonlite_token_decode_size_for_uft16(jsonlite_token *ts);
    
    /** @brief Converts specified token to UTF-16 string.
     *
     * Function converts specified token to UTF-16 string encoding and copy zero terminated string to buffer.
     * @note
     * Function will alloc memory by itself if *buffer == NULL.
     * In this case you are responsible for memory releasing by using free() function.
     * @param ts jsonlite token
     * @return length in bytes of converted string.
     */
    size_t jsonlite_token_decode_to_uft16(jsonlite_token *ts, uint16_t **buffer);

    /** @brief Converts hex digit to integer value.
     *
     * @param c a ASCII character.
     * @return integer value of hex character, 
     * if character belongs to set [0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,a,b,c,d,e,f]; otherwise 0xFF.
     */
    uint8_t jsonlite_hex_char_to_uint8(uint8_t c);
    
#ifdef __cplusplus
}
#endif

#endif
