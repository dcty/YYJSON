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

#ifndef JSONLITE_TYPES_H
#define JSONLITE_TYPES_H

typedef enum {
    jsonlite_result_unknown = -1,
    jsonlite_result_ok,
    jsonlite_result_end_of_stream,
    jsonlite_result_depth_limit,
    jsonlite_result_invalid_argument,
    jsonlite_result_expected_object_or_array,
    jsonlite_result_expected_value,
    jsonlite_result_expected_key_or_end,
    jsonlite_result_expected_key,
    jsonlite_result_expected_colon,
    jsonlite_result_expected_comma_or_end,
    jsonlite_result_invalid_escape,
    jsonlite_result_invalid_number,
    jsonlite_result_invalid_token,
    jsonlite_result_invalid_utf8,
    jsonlite_result_suspended,    
    
    jsonlite_result_not_allowed
} jsonlite_result;


#endif
