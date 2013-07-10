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

#include "../include/jsonlite_builder.h"
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <stdint.h>

#define jsonlite_builder_check_depth()                                  \
do {                                                                    \
    if (builder->state - builder->stack >= builder->stack_depth - 1) {  \
        return jsonlite_result_depth_limit;                             \
    }                                                                   \
} while (0)                                             

typedef enum {
    jsonlite_accept_object_begin = 0x0001,
    jsonlite_accept_object_end = 0x0002,
    jsonlite_accept_array_begin = 0x0004,
    jsonlite_accept_array_end = 0x0008,
    
    jsonlite_accept_key = 0x0010,
    jsonlite_accept_string = 0x0020,
    jsonlite_accept_number = 0x0040,
    jsonlite_accept_boolean = 0x0080,
    jsonlite_accept_null = 0x0100,
    jsonlite_accept_values_only = 0x0200,
    jsonlite_accept_next = 0x0400,
    
    jsonlite_accept_value = 0
    | jsonlite_accept_object_begin
    | jsonlite_accept_array_begin
    | jsonlite_accept_string
    | jsonlite_accept_number
    | jsonlite_accept_boolean
    | jsonlite_accept_null,
    
    jsonlite_accept_continue_object = 0
    | jsonlite_accept_next
    | jsonlite_accept_key
    | jsonlite_accept_object_end,
    jsonlite_accept_continue_array = 0
    | jsonlite_accept_next
    | jsonlite_accept_values_only
    | jsonlite_accept_value
    | jsonlite_accept_array_end
    
} jsonlite_accept;

typedef struct jsonlite_write_state {
    int accept;
} jsonlite_write_state;

typedef struct jsonlite_builder_buffer {
    char data[2048];
    char *cursor;
    char *limit;
    struct jsonlite_builder_buffer *next;
} jsonlite_builder_buffer;

typedef struct jsonlite_builder_struct {
    jsonlite_builder_buffer *first;
    jsonlite_builder_buffer *buffer;
    
    jsonlite_write_state *stack;
    jsonlite_write_state *state;
    ptrdiff_t stack_depth;
    
    char *doubleFormat;
    
    size_t indentation;
} jsonlite_builder_struct;

static int jsonlite_builder_accept(jsonlite_builder builder, jsonlite_accept a);
static void jsonlite_builder_pop_state(jsonlite_builder builder);
static void jsonlite_builder_push_buffer(jsonlite_builder builder);
static void jsonlite_builder_prepare_value_writing(jsonlite_builder builder);
static void jsonlite_builder_raw_char(jsonlite_builder builder, char data);
static void jsonlite_builder_write_uft8(jsonlite_builder builder, const char *data, size_t length);
static void jsonlite_builder_raw(jsonlite_builder builder, const void *data, size_t length);
static void jsonlite_builder_repeat(jsonlite_builder builder, const char ch, size_t count);

jsonlite_builder jsonlite_builder_init(size_t depth) {
    jsonlite_builder builder;
    
    depth = depth < 2 ? 2 : depth;
    
    builder = (jsonlite_builder)calloc(1, sizeof(jsonlite_builder_struct) + depth * sizeof(jsonlite_write_state));
    builder->first = (jsonlite_builder_buffer *)malloc(sizeof(jsonlite_builder_buffer));
    builder->buffer = builder->first;
    builder->buffer->cursor = builder->buffer->data;
    builder->buffer->limit = builder->buffer->data + sizeof(builder->buffer->data);
    builder->buffer->next = NULL;
    
    builder->stack = (jsonlite_write_state *)((uint8_t *)builder + sizeof(jsonlite_builder_struct));
    builder->stack_depth = depth;
    builder->state = builder->stack;
    builder->state->accept = jsonlite_accept_object_begin | jsonlite_accept_array_begin;
    
    builder->indentation = 0;
    jsonlite_builder_set_double_format(builder, "%.16g");
    return builder;
}

jsonlite_result jsonlite_builder_release(jsonlite_builder builder) {
	jsonlite_builder_buffer *b = NULL;
    void *prev;
    
    if (builder == NULL) {
        return jsonlite_result_invalid_argument;
    }

    for (b = builder->first; b != NULL;) {
        prev = b;        
        b = b->next;
        free(prev);
    }

    free(builder->doubleFormat);
    free(builder);
    return jsonlite_result_ok;
}

jsonlite_result jsonlite_builder_set_indentation(jsonlite_builder builder, size_t indentation) {
    if (builder != NULL) {
        builder->indentation = indentation;
        return jsonlite_result_ok;
    }
    return jsonlite_result_invalid_argument;
}

jsonlite_result jsonlite_builder_set_double_format(jsonlite_builder builder, const char *format) {
    if (builder != NULL && format != NULL) {
        builder->doubleFormat = strdup(format);
        return jsonlite_result_ok;
    }
    return jsonlite_result_invalid_argument;
}

static int jsonlite_builder_accept(jsonlite_builder builder, jsonlite_accept a) {
    return (builder->state->accept & a) == a;
}

static void jsonlite_builder_push_state(jsonlite_builder builder) {
    builder->state++;
}

static void jsonlite_builder_pop_state(jsonlite_builder builder) {
    jsonlite_write_state *ws = --builder->state;
    if (jsonlite_builder_accept(builder, jsonlite_accept_values_only) ) {
        ws->accept = jsonlite_accept_continue_array;
    } else {
        ws->accept = jsonlite_accept_continue_object;
    }
}

static void jsonlite_builder_push_buffer(jsonlite_builder builder) {
    jsonlite_builder_buffer *buffer = builder->buffer;
    buffer->next = malloc(sizeof(jsonlite_builder_buffer));
    buffer = builder->buffer = buffer->next;
    
    buffer->cursor = buffer->data;
    buffer->limit = buffer->data + sizeof(buffer->data);
    buffer->next = NULL;
}

static void jsonlite_builder_prepare_value_writing(jsonlite_builder builder) {
    jsonlite_write_state *ws = builder->state;
    if (jsonlite_builder_accept(builder, jsonlite_accept_values_only) ) {
        if (jsonlite_builder_accept(builder, jsonlite_accept_next) ) {
            jsonlite_builder_raw_char(builder, ',');
        }
        if (builder->indentation != 0) {
            jsonlite_builder_raw_char(builder, '\r');
            jsonlite_builder_repeat(builder, ' ', (builder->state - builder->stack) * builder->indentation);
        }
    } else {
        ws->accept &= ~jsonlite_accept_value;
        ws->accept |= jsonlite_accept_key;
    }
    ws->accept |= jsonlite_accept_next;
}

jsonlite_result jsonlite_builder_object_begin(jsonlite_builder builder) {
    if (builder == NULL) {
        return jsonlite_result_invalid_argument;
    }
    
    jsonlite_builder_check_depth();

    if (jsonlite_builder_accept(builder, jsonlite_accept_object_begin)) {
        jsonlite_builder_prepare_value_writing(builder);
        jsonlite_builder_push_state(builder);
        builder->state->accept = jsonlite_accept_object_end | jsonlite_accept_key;
        jsonlite_builder_raw_char(builder, '{');
        return jsonlite_result_ok;
    }
    
    return jsonlite_result_not_allowed;
}

jsonlite_result jsonlite_builder_object_end(jsonlite_builder builder) {
    if (builder == NULL) {
        return jsonlite_result_invalid_argument;
    }

    if (jsonlite_builder_accept(builder, jsonlite_accept_object_end)) {
        jsonlite_builder_pop_state(builder);
        if (builder->indentation != 0) {
            jsonlite_builder_raw_char(builder, '\r');
            jsonlite_builder_repeat(builder, ' ', (builder->state - builder->stack) * builder->indentation);
        }
        jsonlite_builder_raw_char(builder, '}');
        return jsonlite_result_ok;
    }
    
    return jsonlite_result_not_allowed;
}

jsonlite_result jsonlite_builder_array_begin(jsonlite_builder builder) {
    if (builder == NULL) {
        return jsonlite_result_invalid_argument;
    }
    
    jsonlite_builder_check_depth();
    
    if (jsonlite_builder_accept(builder, jsonlite_accept_array_begin)) {
        jsonlite_builder_prepare_value_writing(builder);
        jsonlite_builder_push_state(builder);
        builder->state->accept = jsonlite_accept_array_end 
            | jsonlite_accept_value 
            | jsonlite_accept_values_only;
        jsonlite_builder_raw_char(builder, '[');
        return jsonlite_result_ok;
    }
    
    return jsonlite_result_not_allowed;
}

jsonlite_result jsonlite_builder_array_end(jsonlite_builder builder) {
    if (builder == NULL) {
        return jsonlite_result_invalid_argument;
    }

    if (jsonlite_builder_accept(builder, jsonlite_accept_array_end)) {
        jsonlite_builder_pop_state(builder);
        if (builder->indentation != 0) {
            jsonlite_builder_raw_char(builder, '\r');
            jsonlite_builder_repeat(builder, ' ', (builder->state - builder->stack) * builder->indentation);
        }
        jsonlite_builder_raw_char(builder, ']');
        return jsonlite_result_ok;
    }
    
    return jsonlite_result_not_allowed;
}

static void jsonlite_builder_write_uft8(jsonlite_builder builder, const char *data, size_t length) {
    size_t i;
    jsonlite_builder_raw_char(builder, '\"');
    for (i = 0; i < length; i++) {
        switch (data[i]) {
            case '"':
                jsonlite_builder_raw(builder, "\\\"", 2);
                break;
            case '\\':
                jsonlite_builder_raw(builder, "\\\\", 2);
                break;
            case '\b':
                jsonlite_builder_raw(builder, "\\b", 2);
                break;
            case '\f':
                jsonlite_builder_raw(builder, "\\f", 2);
                break;
            case '\n':
                jsonlite_builder_raw(builder, "\\n", 2);
                break;
            case '\r':
                jsonlite_builder_raw(builder, "\\r", 2);
                break;
            case '\t':
                jsonlite_builder_raw(builder, "\\t", 2);
                break;
            default:
                jsonlite_builder_raw_char(builder, data[i]);
                break;
        }
    }
    jsonlite_builder_raw_char(builder, '\"');
}

jsonlite_result jsonlite_builder_key(jsonlite_builder builder, const char *data, size_t length) {
	jsonlite_write_state *ws;

    if (builder == NULL || data == NULL) {
        return jsonlite_result_invalid_argument;
    }
    
    ws = builder->state;

    if (jsonlite_builder_accept(builder, jsonlite_accept_key) ) {
        if (jsonlite_builder_accept(builder, jsonlite_accept_next) ) {
            jsonlite_builder_raw_char(builder, ',');
        }
        if (builder->indentation != 0) {
            jsonlite_builder_raw_char(builder, '\r');
            jsonlite_builder_repeat(builder, ' ', (builder->state - builder->stack) * builder->indentation);
        }
        jsonlite_builder_write_uft8(builder, data, length);
        if (builder->indentation != 0) {
            jsonlite_builder_raw(builder, ": ", 2);
        } else {
            jsonlite_builder_raw_char(builder, ':');
        }
        ws->accept = jsonlite_accept_value;
        return jsonlite_result_ok;
    }
    
    return jsonlite_result_not_allowed;
}

jsonlite_result jsonlite_builder_string(jsonlite_builder builder, const char *data, size_t length) {
	jsonlite_write_state *ws;

    if (builder == NULL || data == NULL) {
        return jsonlite_result_invalid_argument;
    }
    
    ws = builder->state;

    if (jsonlite_builder_accept(builder, jsonlite_accept_value) ) {
        jsonlite_builder_prepare_value_writing(builder);
        jsonlite_builder_write_uft8(builder, data, length);
        if (jsonlite_builder_accept(builder, jsonlite_accept_values_only) ) {
            ws->accept = jsonlite_accept_continue_array;
        } else {
            ws->accept = jsonlite_accept_continue_object;
        }
        return jsonlite_result_ok;
    }
    
    return jsonlite_result_not_allowed;
}

jsonlite_result jsonlite_builder_int(jsonlite_builder builder, long long value) {
	jsonlite_write_state *ws;
	char buff[128];
	int size = 0;

    if (builder == NULL) {
        return jsonlite_result_invalid_argument;
    }
    
    ws = builder->state;

    if (jsonlite_builder_accept(builder, jsonlite_accept_value) ) {
        jsonlite_builder_prepare_value_writing(builder);
        size = sprintf(buff, "%lld", value);
        jsonlite_builder_raw(builder, buff, size);
        if (jsonlite_builder_accept(builder, jsonlite_accept_values_only) ) {
            ws->accept = jsonlite_accept_continue_array;
        } else {
            ws->accept = jsonlite_accept_continue_object;
        }
        return jsonlite_result_ok;
    }
    
    return jsonlite_result_not_allowed;
}

jsonlite_result jsonlite_builder_double(jsonlite_builder builder, double value) {
	jsonlite_write_state *ws;
	char buff[128];
	int size = 0;

    if (builder == NULL) {
        return jsonlite_result_invalid_argument;
    }
    
    ws = builder->state;

    if (jsonlite_builder_accept(builder, jsonlite_accept_value) ) {
        jsonlite_builder_prepare_value_writing(builder);
        size = sprintf(buff, builder->doubleFormat, value);
        jsonlite_builder_raw(builder, buff, size);
        if (jsonlite_builder_accept(builder, jsonlite_accept_values_only) ) {
            ws->accept = jsonlite_accept_continue_array;
        } else {
            ws->accept = jsonlite_accept_continue_object;
        }
        return jsonlite_result_ok;
    }
    
    return jsonlite_result_not_allowed;
}

jsonlite_result jsonlite_builder_true(jsonlite_builder builder) {
	static const char value[] = "true";
    jsonlite_write_state *ws;

    if (builder == NULL) {
        return jsonlite_result_invalid_argument;
    }
    
	ws = builder->state;
    if (!(jsonlite_builder_accept(builder, jsonlite_accept_value) )) {
        
        return jsonlite_result_not_allowed;
    }
    
    jsonlite_builder_prepare_value_writing(builder);
    jsonlite_builder_raw(builder, (char *)value, sizeof(value) - 1);
    if (jsonlite_builder_accept(builder, jsonlite_accept_values_only) ) {
        ws->accept = jsonlite_accept_continue_array;
    } else {
        ws->accept = jsonlite_accept_continue_object;
    }
    return jsonlite_result_ok;
}

jsonlite_result jsonlite_builder_false(jsonlite_builder builder) {
	static const char value[] = "false";
	jsonlite_write_state *ws;

    if (builder == NULL) {
        return jsonlite_result_invalid_argument;
    }
    
    ws = builder->state;
    if (!(jsonlite_builder_accept(builder, jsonlite_accept_value) )) {
        
        return jsonlite_result_not_allowed;
    }

    jsonlite_builder_prepare_value_writing(builder);
    jsonlite_builder_raw(builder, (char *)value, sizeof(value) - 1);
    if (jsonlite_builder_accept(builder, jsonlite_accept_values_only) ) {
        ws->accept = jsonlite_accept_continue_array;
    } else {
        ws->accept = jsonlite_accept_continue_object;
    }
    return jsonlite_result_ok;
}

jsonlite_result jsonlite_builder_null(jsonlite_builder builder) {
	static const char value[] = "null";
    jsonlite_write_state *ws;

    if (builder == NULL) {
        return jsonlite_result_invalid_argument;
    }
    
	ws = builder->state;
    if (!(jsonlite_builder_accept(builder, jsonlite_accept_value) )) {
        
        return jsonlite_result_not_allowed;
    }
    
    jsonlite_builder_prepare_value_writing(builder);
    jsonlite_builder_raw(builder, (char *)value, sizeof(value) - 1);
    if (jsonlite_builder_accept(builder, jsonlite_accept_values_only) ) {
        ws->accept = jsonlite_accept_continue_array;
    } else {
        ws->accept = jsonlite_accept_continue_object;
    }
    return jsonlite_result_ok;
}
 
static void jsonlite_builder_raw(jsonlite_builder builder, const void *data, size_t length) {
    jsonlite_builder_buffer *buffer = builder->buffer;
    size_t write_limit = buffer->limit - buffer->cursor;
    if (write_limit >= length) {
        memcpy(buffer->cursor, data, length); // LCOV_EXCL_LINE
        buffer->cursor += length;
    } else {
        memcpy(buffer->cursor, data, write_limit); // LCOV_EXCL_LINE
        buffer->cursor += write_limit;
        
        jsonlite_builder_push_buffer(builder);
        jsonlite_builder_raw(builder, (char *)data + write_limit, length - write_limit);
    }
}

static void jsonlite_builder_repeat(jsonlite_builder builder, const char ch, size_t count) {
    jsonlite_builder_buffer *buffer = builder->buffer;
    size_t write_limit = buffer->limit - buffer->cursor;
    if (write_limit >= count) {
        memset(buffer->cursor, ch, count); // LCOV_EXCL_LINE
        buffer->cursor += count;
    } else {
        memset(buffer->cursor, ch, write_limit); // LCOV_EXCL_LINE
        buffer->cursor += write_limit;
        
        jsonlite_builder_push_buffer(builder);
        jsonlite_builder_repeat(builder, ch, count - write_limit);
    }
}

static  void jsonlite_builder_raw_char(jsonlite_builder builder, char data) {
    jsonlite_builder_buffer *buffer = builder->buffer;
    if (buffer->cursor >= buffer->limit) {
        jsonlite_builder_push_buffer(builder);
    }
    *builder->buffer->cursor++ = data;
}

jsonlite_result jsonlite_builder_raw_key(jsonlite_builder builder, const void *data, size_t length) {
	jsonlite_write_state *ws;

    if (builder == NULL || data == NULL || length == 0) {
        return jsonlite_result_invalid_argument;
    }
    
    ws = builder->state;
    if (jsonlite_builder_accept(builder, jsonlite_accept_key) ) {
        if (jsonlite_builder_accept(builder, jsonlite_accept_next) ) {
            jsonlite_builder_raw(builder, ",", 1);
        }
        
        if (builder->indentation != 0) {
            jsonlite_builder_raw_char(builder, '\r');
            jsonlite_builder_repeat(builder, ' ', (builder->state - builder->stack) * builder->indentation);
        }
        jsonlite_builder_raw_char(builder, '\"');
        jsonlite_builder_raw(builder, data, length);
        jsonlite_builder_raw_char(builder, '\"');
        if (builder->indentation != 0) {
            jsonlite_builder_raw(builder, ": ", 2);
        } else {
            jsonlite_builder_raw_char(builder, ':');
        }
        ws->accept = jsonlite_accept_value;
        return jsonlite_result_ok;
    }
    
    return jsonlite_result_not_allowed;
}

jsonlite_result jsonlite_builder_raw_string(jsonlite_builder builder, const void *data, size_t length) {
    jsonlite_write_state *ws;
    
    if (builder == NULL || data == NULL || length == 0) {
        return jsonlite_result_invalid_argument;
    }
    
    ws = builder->state;
    
    if (jsonlite_builder_accept(builder, jsonlite_accept_value) ) {
        jsonlite_builder_prepare_value_writing(builder);
        jsonlite_builder_raw_char(builder, '\"');
        jsonlite_builder_raw(builder, data, length);
        jsonlite_builder_raw_char(builder, '\"');
        if (jsonlite_builder_accept(builder, jsonlite_accept_values_only) ) {
            ws->accept = jsonlite_accept_continue_array;
        } else {
            ws->accept = jsonlite_accept_continue_object;
        }
        return jsonlite_result_ok;
    }
    
    return jsonlite_result_not_allowed;
}

jsonlite_result jsonlite_builder_raw_value(jsonlite_builder builder, const void *data, size_t length) {
	jsonlite_write_state *ws;

    if (builder == NULL || data == NULL || length == 0) {
        return jsonlite_result_invalid_argument;
    }
    
    ws = builder->state;

    if (jsonlite_builder_accept(builder, jsonlite_accept_value) ) {
        jsonlite_builder_prepare_value_writing(builder);
        jsonlite_builder_raw(builder, data, length);
        if (jsonlite_builder_accept(builder, jsonlite_accept_values_only) ) {
            ws->accept = jsonlite_accept_continue_array;
        } else {
            ws->accept = jsonlite_accept_continue_object;
        }
        return jsonlite_result_ok;
    }
    
    return jsonlite_result_not_allowed;
}

jsonlite_result jsonlite_builder_data(jsonlite_builder builder, char **data, size_t *size) {
	jsonlite_builder_buffer *b;
	char *buff = NULL;

    if (builder == NULL || data == NULL || size == NULL) {
        return jsonlite_result_invalid_argument;
    }
 
	*size = 0;
    for (b = builder->first; b != NULL; b = b->next) {
        *size +=  b->cursor - b->data;
    }
    
    if (*size == 0) {
        return jsonlite_result_not_allowed;
    }
    
    *data = (char*)calloc(*size, 1);
    buff = *data; 
    for (b = builder->first; b != NULL; b = b->next) {
        size_t s = b->cursor - b->data;
        memcpy(buff, b->data, s); // LCOV_EXCL_LINE
        buff += s;
    }
    return jsonlite_result_ok;
}
