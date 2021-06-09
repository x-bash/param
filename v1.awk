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

function str_unquote(str){
    gsub(/\\\"/, "\"", str)
    return substr(str, 2, length(str)-2)
}

function str_unquote_if_quoted(str){
    if (str ~ /^\".+\"$/) #"
    {
        return str_unquote(str)
    }
    return str
}

function append_code(code){
    CODE=CODE "\n" code
}

function append_code_assignment(varname, value) {
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

    gsub("\\\\",    astr, "\001")
    gsub("\\\"",    astr, "\002")
    gsub("\"",      astr, "\003")
    gsub("\\ ",     astr, "\004")

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

function join_optarg_oparr(optarg_id, 
    len, idx, result){

    result = ""
    len = option_arr[ optarg_id KSEP OPTARG_OPARR KSEP LEN ]
    for (idx=1; idx<=len; ++idx) {
        result = result " " option_arr[ optarg_id KSEP OPTARG_OPARR KSEP idx ]
    }

    return result
}

function assert_arr_eq(optarg_id, arg_name, value, sep,
    op_arr_len, i, idx, value_arr_len, value_arr, candidate, sw){

    op_arr_len = option_arr[ optarg_id KSEP OPTARG_OPARR KSEP LEN ]

    value_arr_len = split(value, value_arr, sep)
    for (i=1; i<=value_arr_len; ++i) {
        sw = false
        for (idx=2; idx<=op_arr_len; ++idx) {
            candidate = option_arr[ optarg_id KSEP OPTARG_OPARR KSEP idx ]
            candidate = str_unquote_if_quoted( candidate )
            if ( value_arr[i] == candidate ) {
                sw = true
                break
            }
        }
        if (sw == false) {
            error( "Arg: [" arg_name "] 's part of value is [" value_arr[i] "]\nFail to match any candidate:\n" join_optarg_oparr( optarg_id ) )
            print_helpdoc()
            exit_print(1)
        }
    }
}

function assert_arr_regex(optarg_id, arg_name, value, sep,
    i, value_arr_len, value_arr, sw){

    len = option_arr[ optarg_id KSEP OPTARG_OPARR KSEP LEN ]

    value_arr_len = split(value, value_arr, sep)
    for (i=1; i<=value_arr_len; ++i) {
        sw = false
        for (idx=2; idx<=len; ++idx) {
            val = option_arr[ optarg_id KSEP OPTARG_OPARR KSEP idx ]
            val = str_unquote_if_quoted( val )
            if (match( value_arr[i], val )) {
                sw = true
                break
            }
        }
        if (sw == false) {
            error( "Arg: [" arg_name "] 's part of value is [" value_arr[i] "]\nFail to match any regex pattern:\n" join_optarg_oparr( optarg_id ) )
            print_helpdoc()
            exit_print(1)
        }
    }
}

# op_arg_idx # token_arr_len, token_arr, op_arg_idx,         
function assert(optarg_id, arg_name, arg_val,
    op, sw, idx, len, val){

    op = option_arr[optarg_id KSEP OPTARG_OPARR KSEP 1 ]

    if (op == "=int") {
        if (! match(arg_val, /[+-]?[0-9]+/) ) {    # float is: /[+-]?[0-9]+(.[0-9]+)?/
            error( "Arg: [" arg_name "] value is [" arg_val "]\nIs NOT an integer." )
            print_helpdoc()
            exit_print(1)
        }
    } else if (op == "=") {
        sw = false
        len = option_arr[ optarg_id KSEP OPTARG_OPARR KSEP LEN ]
        for (idx=2; idx<=len; ++idx) {
            val = option_arr[ optarg_id KSEP OPTARG_OPARR KSEP idx ]
            val = str_unquote_if_quoted( val )
            if (arg_val == val) {
                sw = true
                break
            }
        }
        if (sw == false) {
            error( "Arg: [" arg_name "] value is [" arg_val "]\nFail to match any candidates:\n" join_optarg_oparr(optarg_id) )
            print_helpdoc()
            exit_print(1)
        }
    } else if (op == "=~") {
        sw = false
        len = option_arr[ optarg_id KSEP OPTARG_OPARR KSEP LEN ]
        for (idx=2; idx<=len; ++idx) {
            val = option_arr[ optarg_id KSEP OPTARG_OPARR KSEP idx ]
            val = str_unquote_if_quoted( val )
            if (match(arg_val, "^"val"$")) {
                sw = true
                break
            }
        }
        if (sw == false) {
            error( "Arg: [" arg_name "] value is [" arg_val "]\nFail to match any regex pattern:\n" join_optarg_oparr(optarg_id) )
            print_helpdoc()
            exit_print(1)
        }

    } else if (op ~ /^=.$/) {
        sep = substr(op, 2, 1)
        assert_arr_eq( optarg_id, arg_name, arg_val, sep )
    } else if (op ~ /^=~.$/) {
        sep = substr(op, 3, 1)
        assert_arr_regex( optarg_id, arg_name, arg_val, sep )
    } else if (op == "") { 
        # Do nothing.
    } else {
        print "Op[" op "] Not Match any candidates: \n" line > "/dev/stderr"
        exit_print(1)
        return false
    }

    return true
}


function arg_typecheck_then_generate_code(optarg_id, arg_var_name, arg_val,
    def, tmp ){

    assert(optarg_id, arg_var_name, arg_val)

    append_code( "local " arg_var_name  " 2>/dev/null" )
    append_code( arg_var_name "=" quote_string( arg_val ) )
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

    type_arr[name] = str_trim( rest )
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
    option_id_list[ LEN ] = 0

    OPTION_ARGC = "num"
    OPTION_SHORT = "shoft"
    OPTION_TYPE = "type"
    OPTION_DESC = "desc"

    OPTION_M = "M"
    OPTION_NAME = "varname"

    OPTARG_ID = "val_id"
    OPTARG_TYPE = "val_type"
    OPTARG_DEFAULT = "val_default"
    
    OPTARG_DEFAULT_REQUIRED_VALUE = "\001"

    OPTARG_OPARR = "val_oparr"
}

function handle_option_id(option_id,
    arr, arr_len, arg_name, i, sw){

    # Add option_id to option_id_list
    i = option_id_list[ LEN ] + 1
    option_id_list[i] = option_id
    option_id_list[ LEN ] = i

    option_arr[ option_id KSEP OPTION_M ] = false

    arr_len = split( option_id, arr, /\|/ )
    for (i=1; i<arr_len; ++i) {
        arg_name = arr[i]

        if (arg_name == "m") {
            option_arr[ option_id KSEP OPTION_M ] = true
            continue
        }

        if (arg_name !~ /^-/) {
            panic_error("Unexpected option name: \n" option_id)
        }

        if (i == 1) {
            option_arr[ option_id KSEP OPTION_NAME ] = arg_name
        }

        option_alias_2_option_id[ arg_name ] = option_id
    }
}

# name is key_prefix like OPTION_NAME
function handle_optarg_declaration(optarg_1_definition, optarg_name,
    optarg_definition_token1, optarg_name, optarg_type, 
    default_value, tmp, type_rule, i
    ){

    tokenize_argument_into_TOKEN_ARRAY( optarg_1_definition )
    optarg_definition_token1 = TOKEN_ARRAY[ 1 ]

    if (! match(def, /^<[-_A-Za-z0-9]+>/)) {
        panic_error("Unexecpted optarg declaration: \n" optarg_1_definition)
    }

    optarg_name = sub( optarg_definition_token1, 2, RLENGTH-1 )
    option_arr[ optarg_name KSEP OPTARG_ID ] = optarg_name

    optarg_definition_token1 = sub( optarg_definition_token1, RLENGTH+1 )

    if (match( optarg_definition_token1, /^:[-_A-Za-z0-9]+/) ) {
        optarg_type = sub( optarg_definition_token1, 2, RLENGTH ) 
        optarg_definition_token1 = sub( optarg_definition_token1, RLENGTH+1 )
    }

    if (match( optarg_definition_token1 , /^=/) ) {
        default_value = sub( optarg_definition_token1, 2 )
        option_arr[ optarg_name KSEP OPTARG_DEFAULT ] = str_unquote_if_quoted( default_value )
    } else {
        # It means, it is required.
        option_arr[ optarg_name KSEP OPTARG_DEFAULT ] = OPTARG_DEFAULT_REQUIRED_VALUE
    }

    if (TOKEN_ARRAY[ LEN ] >= 2) {
        for ( i=2; i<=TOKEN_ARRAY[ LEN ]; ++i ) {
            option_arr[ optarg_name KSEP OPTARG_OPARR KSEP (i-1) ] = TOKEN_ARRAY[i]
        }
        option_arr[ optarg_name KSEP OPTARG_OPARR KSEP LEN ] = i - 2
    } else {
        type_rule = type_arr[ optarg_type ]
        if (type_rule == "") {
            # panic_error("Unknown type: \n" optarg_type)
            return
        }

        tokenize_argument_into_TOKEN_ARRAY( type_rule )

        for ( i=1; i<=TOKEN_ARRAY[ LEN ]; ++i ) {
            option_arr[ optarg_name KSEP OPTARG_OPARR KSEP i ] = TOKEN_ARRAY[i]
        }
        option_arr[ optarg_name KSEP OPTARG_OPARR KSEP LEN ] = i - 1
    }

}

function parse_param_dsl(line,
    line_arr, i, j, state, tmp, len, nextline,
    option_id) {

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
                option_id = TOKEN_ARRAY[1]
                handle_option_id( option_id )

                option_desc = TOKEN_ARRAY[2]
                option_arr[ option_id KSEP OPTION_DESC ] = option_desc 

                tmp = ""
                for (i=3; i<=TOKEN_ARRAY[LEN]; ++i) {
                    tmp = tmp " " TOKEN_ARRAY[i]
                }
                option_arr[ option_id KSEP 1 ] = tmp
                handle_optarg_declaration( tmp, option_id KSEP 1 )

                j = 1
                while (true) {
                    nextline = str_trim( line[ i + j ] )
                    if ( str_trim( nextline ) ~ /^-/ ) {
                        break
                    }
                    j = j + 1
                    option_arr[ option_id KSEP j ] = nextline
                    handle_optarg_declaration( nextline, option_id KSEP j )
                }
                option_arr[ option_id KSEP LEN ] = j

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
    i, j, option, option_argc, option_id, option_m, option_name ) 
{
    for (i=1; i<option_id_list[ LEN ]; ++i) {
        option_id     = option_id_list[ i ]
        option_m        = option_arr[ option_id KSEP OPTION_M ]

        if ( option_arr_value_set[ option_id ] == true ) {
            if (option_m == true) {
                append_code_assignment(
                    option_name "_n", 
                    option_assignment_count[ option_id ] 
                )
            }
            continue
        }

        option_argc      = option_arr[ option_id KSEP OPTION_ARGC ]

        if ( 0 == option_argc ) {
            continue
        }

        option_name     = option_arr[ option_id KSEP OPTION_NAME ]
        
        gsub(/^--?/, "", option_name)
        if ( true == option_m ) {
            append_code_assignment( 
                option_name "_n",
                1
            )

            option_name = option_name "_" 1
        }

        # required?
        if (option_argc == 1) {
            val = option_default_map[ option_id ]
            if (length(val) == 0) {
                val = option_arr[ option_id KSEP OPTARG_DEFAULT ]
            }

            if (val == OPTARG_DEFAULT_REQUIRED_VALUE) {
                panic_error("Required a value in option: " option_id " " j)
            }

            assert(option_id KSEP 1, option_name, val)

            append_code_assignment(
                option_name,
                val 
            )
            continue
        }

        for ( j=1; j<=option_argc; ++j ) {
            val = option_arr[ option_id KSEP j KSEP OPTARG_DEFAULT ]

            if (val == OPTARG_DEFAULT_REQUIRED_VALUE) {
                panic_error("Required a value in option: " option_id " " j)
            }

            assert(option_id KSEP 1, option_name "_" j, val)

            append_code_assignment( 
                option_name "_" j, 
                val
            )
        }
    }
    
}

###############################
# handle_arguments
###############################
function handle_arguments( 
    i, j, arg_name, arg_name_short, arg_val, option_id, option_argc, count) {

    arg_arr_len = arg_arr[LEN]

    i = 1
    while (i <= arg_arr_len) {
        arg_name = arg_arr[i]

        if ( ( arg_name == "--help") && ( arg_name == "-h") ) {
            print_helpdoc()
            exit_print(1)
        }

        option_id     = option_alias_2_option_id[arg_name]

        if ((option_id == "") && (arg_name ~ /^-[^-]/)) {
            arg_name = substr(arg_name, 2)
            arg_len = split(arg_name, arg_arr, //)
            for (j=1; j<=arg_len; ++j) {
                arg_name_short  = "-" arg_arr[ j ]
                option_id       = option_alias_2_option_id[ arg_name_short ]
                option_name     = option_arr[ option_id KSEP OPTION_NAME ]

                if (option_name == "") {
                    panic_error("option_name not found. [option_id]=" option_id " , [arg_name]=" arg_name_short " , [original arg_name]=" arg_name)
                }

                append_code_assignment(
                    option_name,
                    "true"
                )
            }
            continue
        }

        option_arr_value_set[ option_id ] = true

        option_argc     = option_arr[ option_id KSEP LEN ]
        option_m        = option_arr[ option_id KSEP OPTION_M ]
        option_name  = option_arr[ option_id KSEP OPTION_NAME ]
        gsub(/^--?/, "", option_name)

        # If option_argc == 0, op
        if (option_m == true) {
            counter = (option_assignment_count[ option_id ] || 0) + 1
            option_assignment_count[ option_id ] = counter
            option_name = option_name "_" counter
        }

        # Consider unhandled arguments are rest_argv
        if ( !( arg_name ~ /--?/ ) ) break
        
        if (option_argc == 0) {
            # print code XXX=true
            append_code_assignment(
                option_name,
                "true"
            )
        } else if (option_argc == 1) {
            i = i + 1
            arg_val = arg_arr[i]
            if (i > arg_arr_len) {
                panic_error(i)
            }

            arg_typecheck_then_generate_code(
                option_id KSEP 1
                option_name, 
                arg_val,
            )
        } else {
            for ( j=1; j<=option_argc; ++j ) {
                i += 1
                arg_val = arg_arr[i]
                if (i > arg_arr_len) {
                    panic_error(i)
                }

                arg_typecheck_then_generate_code(
                    option_id KSEP j
                    option_name "_" j,
                    arg_val,
                )
            }
        }
        i += 1
    }

    check_required_option_ready()

    if (i <= arg_arr_len) {

        # handle rest argv
        # TODO: print code set -- arguments
        append("set --")

        rest_argv[ LEN ] = 0

        for (j=i; j<=arg_arr_len; ++j) {
            tmp = tmp " \"$" i "\""
        }

        # TODO: using subcommand
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
    # TODO: setting default values
    parse_param_dsl($0)
}

NR==3 {
    # handle arguments
    split($0, arg_arr, ARG_SEP)
}

###############################
# Line 4: Defaults As Map
###############################

NR>=4 {
    # Setting default values
    if (keyline == "") {
        keyline = option_alias_2_option_id[ $0 ]
    } else {
        option_default_map[keyline] = $0
        keyline = ""
    }
}

END {
    handle_arguments()
    print_code()
}
