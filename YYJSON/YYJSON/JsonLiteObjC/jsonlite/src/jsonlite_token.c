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

#include "../include/jsonlite_token.h"
#include <stdlib.h>

#ifdef _MSC_VER
#include <intrin.h>

static uint32_t __inline jsonlite_clz( uint32_t x ) {
   unsigned long r = 0;
   _BitScanForward(&r, x);
   return r;
}

#else

#define jsonlite_clz(x) __builtin_clz((x))

#endif

uint8_t jsonlite_hex_char_to_uint8(uint8_t c) {
    uint8_t res = 0xFF;
    if (c >= '0' && c <= '9') {
        res = c - '0';
    } else if (c >= 'a' && c <= 'f') {
        res = c - 'a' + 10;
    } else if (c >= 'A' && c <= 'F') {
        res = c - 'A' + 10;
    }
    return res;
}

static int unicode_char_to_utf16(uint32_t ch, uint16_t *utf16) {
    uint32_t v = ch - 0x10000;
    uint32_t vh = v >> 10;
    uint32_t vl = v & 0x3FF;
	if (ch <= 0xFFFF) {
        *utf16 = (uint16_t)ch;
        return 1;
    }
    
    *utf16++ = (uint16_t)(0xD800 + vh);
    *utf16 = (uint16_t)(0xDC00 + vl);
    return 2;
}

size_t jsonlite_token_decode_size_for_uft8(jsonlite_token *ts) {
    if (ts == NULL) {
        return 0;
    }
    
    return ts->end - ts->start + 1;
}

size_t jsonlite_token_decode_to_uft8(jsonlite_token *ts, uint8_t **buffer) {
    size_t size = jsonlite_token_decode_size_for_uft8(ts);
    if (size == 0 || buffer == NULL) {
        return 0;
    }
    
    const uint8_t *p = ts->start;
    const uint8_t *l = ts->end;
    uint32_t value, utf32;
  	uint8_t *c = *buffer = (uint8_t *)malloc(size);
    int res;
step:
    if (p == l)         goto done;
    if (*p == '\\')     goto escaped;
    if (*p >= 0x80)     goto utf8;
    *c++ = *p++;
    goto step;
escaped:
    switch (*++p) {
        case 34:    *c++ = '"';     p++; goto step;
        case 47:    *c++ = '/';     p++; goto step;
        case 92:    *c++ = '\\';    p++; goto step;
        case 98:    *c++ = '\b';    p++; goto step;
        case 102:   *c++ = '\f';    p++; goto step;
        case 110:   *c++ = '\n';    p++; goto step;
        case 114:   *c++ = '\r';    p++; goto step;
        case 116:   *c++ = '\t';    p++; goto step;
	}

    // UTF-16    
    p++;
    utf32 = jsonlite_hex_char_to_uint8(*p++);
    utf32 = (uint32_t)(utf32 << 4) | jsonlite_hex_char_to_uint8(*p++);
    utf32 = (uint32_t)(utf32 << 4) | jsonlite_hex_char_to_uint8(*p++);
    utf32 = (uint32_t)(utf32 << 4) | jsonlite_hex_char_to_uint8(*p++);
    if (0xD800 > utf32 || utf32 > 0xDBFF) goto encode;
    
    // UTF-16 Surrogate
    p += 2;
    utf32 = (utf32 - 0xD800) << 10;
    value = jsonlite_hex_char_to_uint8(*p++);
    value = (uint32_t)(value << 4) | jsonlite_hex_char_to_uint8(*p++);
    value = (uint32_t)(value << 4) | jsonlite_hex_char_to_uint8(*p++);
    value = (uint32_t)(value << 4) | jsonlite_hex_char_to_uint8(*p++);
    utf32 += value - 0xDC00 + 0x10000;
encode:
    if (utf32 < 0x80) {
        *c++ = (uint8_t)utf32;
    } else if (utf32 < 0x0800) {
        c[1] = (uint8_t)(utf32 & 0x3F) | 0x80;
        utf32 = utf32 >> 6;
        c[0] = (uint8_t)utf32 | 0xC0;
        c += 2;
    } else if (utf32 < 0x10000) {
        c[2] = (uint8_t)(utf32 & 0x3F) | 0x80;
        utf32 = utf32 >> 6;
        c[1] = (uint8_t)(utf32 & 0x3F) | 0x80;
        utf32 = utf32 >> 6;
        c[0] = (uint8_t)utf32 | 0xE0;
        c += 3;
    } else {
        c[3] = (uint8_t)(utf32 & 0x3F) | 0x80;
        utf32 = utf32 >> 6;
        c[2] = (uint8_t)(utf32 & 0x3F) | 0x80;
        utf32 = utf32 >> 6;
        c[1] = (uint8_t)(utf32 & 0x3F) | 0x80;
        utf32 = utf32 >> 6;
        c[0] = (uint8_t)utf32 | 0xF0;
        c += 4;
    }
    goto step;
utf8:
    res = jsonlite_clz(((*p) ^ 0xFF) << 0x19);
    *c++ = *p++;
    switch (res) {
        case 3: *c++ = *p++;
        case 2: *c++ = *p++;
        case 1: *c++ = *p++;
    }
    goto step;
done:
    *c = 0;
    return c - *buffer;
}

size_t jsonlite_token_decode_size_for_uft16(jsonlite_token *ts) {
    if (ts == NULL) {
        return 0;
    }
    
    return (ts->end - ts->start + 1) * sizeof(uint16_t);
}

size_t jsonlite_token_decode_to_uft16(jsonlite_token *ts, uint16_t **buffer) {
    size_t size = jsonlite_token_decode_size_for_uft16(ts);
    if (size == 0 || buffer == NULL) {
        return 0;
    }
    
    const uint8_t *p = ts->start;
    const uint8_t *l = ts->end;
    uint16_t utf16;
    uint16_t *c = *buffer = (uint16_t *)malloc(size);
    int res;    
step:
    if (p == l)         goto done;
    if (*p == '\\')     goto escaped;
    if (*p >= 0x80)     goto utf8;
    *c++ = *p++;
    goto step;
escaped:
    switch (*++p) {
        case 34:    *c++ = '"';     p++; goto step;
        case 47:    *c++ = '/';     p++; goto step;
        case 92:    *c++ = '\\';    p++; goto step;
        case 98:    *c++ = '\b';    p++; goto step;
        case 102:   *c++ = '\f';    p++; goto step;
        case 110:   *c++ = '\n';    p++; goto step;
        case 114:   *c++ = '\r';    p++; goto step;
        case 116:   *c++ = '\t';    p++; goto step;
	}
    
    // UTF-16
    p++;
    utf16 = jsonlite_hex_char_to_uint8(*p++);
    utf16 = (uint16_t)(utf16 << 4) | jsonlite_hex_char_to_uint8(*p++);
    utf16 = (uint16_t)(utf16 << 4) | jsonlite_hex_char_to_uint8(*p++);
    utf16 = (uint16_t)(utf16 << 4) | jsonlite_hex_char_to_uint8(*p++);
    *c++ = utf16;
    if (0xD800 > utf16 || utf16 > 0xDBFF) goto step;
    
    // UTF-16 Surrogate
    p += 2;
    utf16 = jsonlite_hex_char_to_uint8(*p++);
    utf16 = (uint16_t)(utf16 << 4) | jsonlite_hex_char_to_uint8(*p++);
    utf16 = (uint16_t)(utf16 << 4) | jsonlite_hex_char_to_uint8(*p++);
    utf16 = (uint16_t)(utf16 << 4) | jsonlite_hex_char_to_uint8(*p++);
    *c++ = utf16;
    goto step;
utf8:
    res = jsonlite_clz(((*p) ^ 0xFF) << 0x19);
    uint32_t code = (*p & (0xFF >> (res + 1)));
    switch (res) {
        case 3: code = (code << 6) | (*++p & 0x3F);
        case 2: code = (code << 6) | (*++p & 0x3F);
        case 1: code = (code << 6) | (*++p & 0x3F);
        case 0: ++p;
    }
    
    c += unicode_char_to_utf16(code, c);
    goto step;
done:
    *c = 0;
    return (c - *buffer) * sizeof(uint16_t);
}
