BEGIN {
    false = 0;  true = 1
    LEN="len"
    KSEP = "\034"
}

function panic_error(msg){
    print msg > "/dev/stderr"
}

function print_code(){
    print CODE
}

function quote_string(str){
    gsub(/\"/, "\\\"", str)
    return "\"" str "\""
}

function append_code(code){
    CODE=CODE "\n" code
}

function append_code_setval(varname, value) {
    append_code( "local " varname " 2>/dev/null" )
    append_code( varname "=" value )
}

function exit_print(code){
    print "return " code " 2>/dev/null || exit " code
    exit code
}

# output certain kinds of array
function str_trim(astr){
    gsub(/^[ \t\b\v\n]+/, "", astr)
    gsub(/[ \t\b\v\n]+$/, "", astr)
    return astr
}

function str_trim_left(astr){
    gsub(/^[ \t\b\v\n]+/, "", astr)
    return astr
}

# TOKEN_ARRAY
function tokenize_argument_into_TOKEN_ARRAY(astr,
    len, tmp ){

    original_astr = astr

    gsub("\\\\", astr, "\001")
    gsub("\\\"", astr, "\002")
    gsub("\"", astr, "\003")
    gsub("\\ ", astr, "\004")

    
    astr = str_trim_left(astr)
    TOKEN_ARRAY[LEN] = 0
    while (length(astr) > 0){
        if (match(/\003[^\003]+\003/, astr)) {
            len = TOKEN_ARRAY[LEN] + 1
            tmp = substr(astr, 1, RLENGTH)
            gsub("\004", tmp, " ")      # Unwrap
            gsub("\003", tmp, "")       # Unwrap
            gsub("\002", tmp, "\"")     
            gsub("\001", tmp, "\\")     # Unwrap
            TOKEN_ARRAY[len] = tmp
            TOKEN_ARRAY[LEN] = len
            astr = substr(astr, RLENGTH+1)

        } else if (match(/^[^ \t\v\003]+/), astr){ #"

            len = TOKEN_ARRAY[LEN] + 1
            tmp = substr(astr, 1, RLENGTH)
            gsub("\004", tmp, " ")
            gsub("\003", tmp, "")
            gsub("\002", tmp, "\"")
            gsub("\001", tmp, "\\\\")   # Notice different
            TOKEN_ARRAY[len] = tmp
            TOKEN_ARRAY[LEN] = len
            astr = substr(astr, RLENGTH+1)

            if (match(/\003[^\003]+\003/, astr)) {
                tmp = substr(astr, 1, RLENGTH)
                gsub("\004", tmp, " ")      # Unwrap
                gsub("\003", tmp, "")       # Unwrap
                gsub("\002", tmp, "\"")     
                gsub("\001", tmp, "\\")     # Unwrap
                TOKEN_ARRAY[len] = TOKEN_ARRAY[len] tmp

                astr = substr(astr, RLENGTH+1)
            }
        } else {
            panic_error("Fail to tokenzied following line:\n" original_astr)
        }

        astr = str_trim_left(astr)
    }
}

### Type check

function join_to_rule_line(option_val_name, 
    len, idx, result){

    result = ""
    len = option_arr[ option_val_name KSEP OPTION_VAL_OPARR KSEP LEN ]
    for (idx=1; idx<=len; ++idx) {
        result = result " " option_arr[ option_val_name KSEP OPTION_VAL_OPARR KSEP idx ]
    }

    return result
}

function assert_arr_eq(option_val_name, arg_name, value, sep,
    i, idx, value_arr_len, value_arr, sw){

    op_arr_len = option_arr[ option_val_name KSEP OPTION_VAL_OPARR KSEP LEN ]

    value_arr_len = split(value, value_arr, sep)
    for (i=1; i<=value_arr_len; ++i) {
        sw = false
        for (idx=2; idx<=op_arr_len; ++idx) {
            val = option_arr[ option_val_name KSEP OPTION_VAL_OPARR KSEP idx ]
            if ( value_arr[i] == val ) {
                sw = true
                break
            }
        }
        if (sw == false) {
            error( "Arg: [" arg_name "] 's part of value is [" value_arr[i] "]\nFail to match any candidate:\n" join_to_rule_line( option_val_name ) )
            print_helpdoc()
            exit_print(1)
        }
    }
}

function assert_arr_regex(option_val_name, arg_name, value, sep,
    i, value_arr_len, value_arr, sw){

    len = option_arr[ option_val_name KSEP OPTION_VAL_OPARR KSEP LEN ]

    value_arr_len = split(value, value_arr, sep)
    for (i=1; i<=value_arr_len; ++i) {
        sw = false
        for (idx=2; idx<=len; ++idx) {
            val = option_arr[ option_val_name KSEP OPTION_VAL_OPARR KSEP idx ]
            if (match( value_arr[i], val )) {
                sw = true
                break
            }
        }
        if (sw == false) {
            error( "Arg: [" arg_name "] 's part of value is [" value_arr[i] "]\nFail to match any regex pattern:\n" join_to_rule_line( option_val_name ) )
            print_helpdoc()
            exit_print(1)
        }
    }
}

# op_arg_idx # token_arr_len, token_arr, op_arg_idx,         
function assert(option_val_name, arg_name, arg_val,
    op, sw, idx, len, val){

    op = option_arr[option_val_name KSEP OPTION_VAL_OPARR KSEP 1 ]

    if (op == "=int") {
        if (! match(arg_val, /[+-]?[0-9]+/) ) {    # float is: /[+-]?[0-9]+(.[0-9]+)?/
            error( "Arg: [" arg_name "] value is [" arg_val "]\nIs NOT an integer." )
            print_helpdoc()
            exit_print(1)
        }
    } else if (op == "=") {
        sw = false
        len = option_arr[ option_val_name KSEP OPTION_VAL_OPARR KSEP LEN ]
        for (idx=2; idx<=len; ++idx) {
            val = option_arr[ option_val_name KSEP OPTION_VAL_OPARR KSEP idx ]
            if (arg_val == val) {
                sw = true
                break
            }
        }
        if (sw == false) {
            error( "Arg: [" arg_name "] value is [" arg_val "]\nFail to match any candidates:\n" join_to_rule_line(option_val_name) )
            print_helpdoc()
            exit_print(1)
        }
    } else if (op == "=~") {
        sw = false
        len = option_arr[ option_val_name KSEP OPTION_VAL_OPARR KSEP LEN ]
        for (idx=2; idx<=len; ++idx) {
            val = option_arr[ option_val_name KSEP OPTION_VAL_OPARR KSEP idx ]
            if (match(arg_val, "^"val"$")) {
                sw = true
                break
            }
        }
        if (sw == false) {
            error( "Arg: [" arg_name "] value is [" arg_val "]\nFail to match any regex pattern:\n" join_to_rule_line(option_val_name) )
            print_helpdoc()
            exit_print(1)
        }

    } else if (op ~ /^=.$/) {
        sep = substr(op, 2, 1)
        assert_arr_eq(option_val_name, arg_name, arg_val, sep)
    } else if (op ~ /^=~.$/) {
        sep = substr(op, 3, 1)
        assert_arr_regex(option_val_name, arg_name, arg_val, sep)
    } else {
        print "Op[" op "] Not Match any candidates: \n" line > "/dev/stderr"
        exit_print(1)
        return false
    }

    return true
}


function arg_typecheck_then_generate_code(option_val_name, arg_var_name, arg_val,
    def, tmp ){

    assert(option_val_name, arg_var_name, arg_val)

    append_code( "local " arg_var_name  " 2>/dev/null" )
    append_code( arg_var_name "=" quote_string(arg_val) )
}

###############################
# Step 1 Utils: Global types
###############################
BEGIN {
    type_arr[LEN]=0
}

function type_arr_add(line,
    name, rest){
    line = str_trim(line)

    match("/^[_\-A-Za-z0-9]+/", "", line)
    if (RLENGTH <= 0) {
        panic_error("Should not happned for type lines")
    }
    
    name = substr(line, 1, RLENGTH)
    rest = substr(line, RLENGTH+1)

    type_arr[name] = str_trim(rest)
}

###############################
# Step 2 Utils: Parse param DSL
###############################
BEGIN {
    advise_arr[ LEN ]=0
    arg_arr[ LEN ]=0
    subcommand_arr[ LEN ]=0

    rest_argv_arr[ LEN ]=0
    # argument_detail_arr

    RS="\001"
}

BEGIN {
    option_arr[ LEN ]=0
    option_name_list[ LEN ] = 0

    OPTION_NUM = "num"
    OPTION_SHORT = "shoft"
    OPTION_TYPE = "type"
    OPTION_DESC = "desc"

    OPTION_M = "M"
    OPTION_VARNAME = "varname"

    OPTION_VAL_NAME = "val_name"
    OPTION_VAL_TYPE = "val_type"
    OPTION_VAL_DEFAULT = "val_default"
    OPTION_VAL_OPARR = "val_oparr"
}

function handle_option_name(option_name,
    arr, arr_len, arg_name, i, sw){

    # Add option_name to option_name_list
    i = option_name_list[ LEN ] + 1
    option_name_list[i] = option_name
    option_name_list[ LEN ] = i

    option_arr[ option_name KSEP OPTION_M ] = false

    arr_len = split( option_name, arr, /\|/ )
    for (i=1; i<arr_len; ++i) {
        arg_name = arr[i]

        if (arg_name == "m") {
            option_arr[ option_name KSEP OPTION_M ] = true
            continue
        }

        if (arg_name !~ /^-/) {
            panic_error("Unexpected option name: \n" option_name)
        }

        if (i == 1) {
            option_arr[ option_name KSEP OPTION_VARNAME ] = arg_name
        }

        arg_name_2_option_name[ arg_name ] = option_name
    }
}

function handle_option_value(arg_typedef, name,
    def, def_name, def_type, tmp, type_rule, i){

    # arg_typedef =>  meta  arg_type
    tokenize_argument_into_TOKEN_ARRAY( arg_typedef )
    def = TOKEN_ARRAY[ 1 ]

    if (! match(def, /^<[-_A-Za-z0-9]+>/)) {
        panic_error("Unexecpted option value name: \n" arg_typedef)
    }

    def_name = sub(def, 2, RLENGTH-1)
    option_arr[ name KSEP OPTION_VAL_NAME ] = def_name

    def = sub(def, RLENGTH+1)

    if (match(def, /^:[-_A-Za-z0-9]+/)) {
        def_type = sub(def, 2, RLENGTH)
        def = sub(def, RLENGTH+1)
    }

    if (match(def, /^=/)) {
        def_default = sub(def, 2)
        # TODO: Unquote the def_default
        option_arr[ name KSEP OPTION_VAL_DEFAULT ] = def_default
    }

    if (TOKEN_ARRAY[ LEN ] >= 2) {
        for ( i=2; i<=TOKEN_ARRAY[ LEN ]; ++i ) {
            option_arr[ name KSEP OPTION_VAL_OPARR KSEP (i-1) ] = TOKEN_ARRAY[i]
        }
        option_arr[ name KSEP OPTION_VAL_OPARR KSEP LEN ] = i - 2
    } else {
        type_rule = type_arr[ def_type ]
        if (type_rule == "") {
            panic_error("Unknow rule name: \n" def_type)
        }

        tokenize_argument_into_TOKEN_ARRAY( type_rule )

        for ( i=1; i<=TOKEN_ARRAY[ LEN ]; ++i ) {
            option_arr[ name KSEP OPTION_VAL_OPARR KSEP i ] = TOKEN_ARRAY[i]
        }
        option_arr[ name KSEP OPTION_VAL_OPARR KSEP LEN ] = i - 1
    }

}

function parse_param_dsl(line,
    line_arr, i, j, state, tmp, len, nextline) {

    state = 0
    STATE_ADVISE        = 1
    STATE_TYPE          = 2
    STATE_SCOPE         = 3
    STATE_OPTION        = 4
    STATE_SUBCOMMAND    = 5
    STATE_ARGUMENT      = 6

    line_arr_len = split(line, line_arr, "\n")

    for (i=1; i<=line_arr_len; ++i) {
        line = line_arr[i]

        line = str_trim( line )

        if (line ~ /^advise:/) {
            state = STATE_ADVISE
        } else if (line ~ /^type:/) {
            state = STATE_TYPE
        } else if (line ~ /^scope:/) {
            state = STATE_SCOPE
        } else if (line ~ /^option\s:\s+/) {
            state = STATE_OPTION
        } else if (line ~ /^subcommand\s:\s+/) {
            state = STATE_SUBCOMMAND
        } else if (line ~ /^argument\s:\s+/) {
            state = STATE_ARGUMENT
        } else {

            if (state == STATE_ADVISE) {
                tmp = advise_arr[ LEN ] + 1
                advise_arr[ LEN ] = tmp
                advise_arr[ tmp ] = line

            } else if (state == STATE_OPTION) {
                if (line !~ /^-/) {
                    panic_error("Expect option starting with - or -- :\n" line)
                }

                len = option_arr[ LEN ] + 1
                option_arr[ LEN ] = len
                option_arr[ len ] = line

                tokenize_argument_into_TOKEN_ARRAY( line )
                option_name = TOKEN_ARRAY[1]
                handle_option_name( option_name )

                option_desc = TOKEN_ARRAY[2]
                option_arr[ option_name KSEP OPTION_DESC ] = option_desc 

                tmp = ""
                for (i=3; i<=TOKEN_ARRAY[LEN]; ++i) {
                    tmp = tmp " " TOKEN_ARRAY[i]
                }
                option_arr[ option_name KSEP 1 ] = tmp
                # TODO: handle the first option value
                # Get header() and type

                j = 1
                while (true) {
                    nextline = str_trim( line[ i + j ] )
                    if ( str_trim( nextline ) ~ /^-/ ) {
                        break
                    }
                    j = j + 1
                    option_arr[ option_name KSEP j ] = nextline
                    # TODO: handle the second option value
                }
                option_arr[ option_name KSEP LEN ] = j

            } else if ( state == STATE_TYPE ) {
                type_arr_add( line )

            } else if ( state == STATE_SUBCOMMAND ) {
                tmp = subcommand_arr[ LEN ] + 1
                subcommand_arr[ LEN ] = tmp
                subcommand_arr[ tmp ] = line

            } else if (state == STATE_ARGUMENT) {
                tmp = rest_argv_arr[ LEN ] + 1
                rest_argv_arr[ LEN ] = tmp
                rest_argv_arr[ tmp ] = line
            }

        }
    }
}


###############################
# Step 3 Utils: Handle code
###############################


function check_required_option_ready(
    i, j, option, option_num, option_name, option_m, option_varname ) 
{
    for (i=1; i<option_name_list[ LEN ]; ++i) {
        option_name     = option_name_list[ i ]
        option_m        = option_arr[ option_name KSEP OPTION_M ]

        if ( option_arr_value_set[ option_name ] == true ) {
            if (option_m == true) {
                option_varname = option_varname "_" n
                append_code_setval( option_varname, arg_count[ option_name ] )
            }
            continue
        }

        option_num = option_arr[ option_name KSEP OPTION_NUM ]
        option_varname  = option_arr[ option_name KSEP OPTION_VARNAME ]
        
        gsub(/^--?/, "", option_varname)
        if (option_m == true) {
            option_varname = option_varname "_" 1
        }

        if (option_num == 0) {
            continue
        }

        # required?
        if (option_num == 1) {
            val = arg_default_map[ option_name ]
            if (length(val) == 0) {
                val = option_arr[ option_name KSEP OPTION_VAL_DEFAULT ]
            }

            append_code_setval( 
                option_varname, 
                val 
            )
            continue
        }

        for ( j=1; j<=option_num; ++j ) {
            append_code_setval( 
                option_varname "_" j, 
                option_arr[ option_name KSEP j KSEP OPTION_VAL_DEFAULT ] 
            )
        }
    }
    
}

###############################
# handle_arguments
###############################
function handle_arguments( 
    i, j, arg_name, arg_val, option_name, option_num, count) {

    arg_arr_len = arg_arr[LEN]

    i = 1
    while (i <= arg_arr_len) {
        arg_name = arg_arr[i]

        if ( ( arg_name == "--help") && ( arg_name == "-h") ) {
            print_helpdoc()
            exit_print(1)
        }

        option_name     = arg_name_2_option_name[arg_name]
        option_arr_value_set[ option_name ] = true

        option_num      = option_arr[ option_name KSEP LEN ]
        option_m        = option_arr[ option_name KSEP OPTION_M ]
        option_varname  = option_arr[ option_name KSEP OPTION_VARNAME ]
        gsub(/^--?/, "", option_varname)
        if (option_m == true) {
            counter = (arg_count[ option_name ] || 0) + 1
            arg_count[ option_name ] = counter
            option_varname = option_varname "_" counter
        }

        # TODO: add counter

        # Consider unhandled arguments are rest_argv
        if ( !( arg_name ~ /--?/ ) ) break
        
        if (option_num == 0) {
            # OK, enable
            # print code XXX=true
        } else if (option_num == 1) {
            i = i + 1
            arg_val = arg_arr[i]
            if (i > arg_arr_len) {
                panic_error(i)
            }

            arg_typecheck_then_generate_code(
                option_name KSEP 1
                option_varname, 
                arg_val,
            )
        } else {
            for ( j=1; j<=option_num; ++j ) {
                i += 1
                arg_val = arg_arr[i]
                if (i > arg_arr_len) {
                    panic_error(i)
                }

                arg_typecheck_then_generate_code(
                    option_name KSEP j
                    option_varname "_" j,
                    arg_val,
                )
            }
        }
        i += 1
    }

    if (i <= arg_arr_len) {

       
        # Check if all required options are ready.

        # handle rest argv
        # TODO: print code set -- arguments

        # TODO: typecheck the argument value
    } else {
        append_code("set --")
    }
}


NR==1 {
    type_arr_len = split($0, type_arr, /[ \t\v]+/)
    for (i=1; i<=type_arr_len; ++i) {
        type_arr_add(type_arr[i])
    }
}


NR==2 {
    parse_param_dsl($0)
    # analyze option line

    # analyze subcommand lines
}

NR==3 {
    # handle arguments
    split($0, arg_arr, ARG_SEP)
}

###############################
# Line 4: Defaults As Map
###############################

NR>=4 {
    if (keyline == "") {
        keyline = $0
    } else {
        arg_default_map[keyline] = $0
        keyline = ""
    }
}

END {
    handle_arguments()
    print_code()
}
