BEGIN {
    false = 0;  true = 1
    LEN="len"
    KSEP = "\034"

    EXIT_CODE = -1
}

function exit_now(code){
    EXIT_CODE = code
    exit code
}

function panic_error(msg){
    print msg > "/dev/stderr"
    print "return 1 2>/dev/null || exit 1 2>/dev/null"
    exit_now(1)
}

function debug(msg){
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

function exit_print(exit_code){
    print "return " exit_code " 2>/dev/null || exit " exit_code
    exit_now( exit_code )
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

    gsub(/\\\\/,    "\001", astr)
    gsub(/\\\"/,    "\002", astr) # "
    gsub("\"",      "\003", astr) # "
    gsub(/\\\ /,     "\004", astr)

    astr = str_trim(astr)

    TOKEN_ARRAY[LEN] = 0
    while (length(astr) > 0){
        if (match(astr, /^\003[^\003]+\003/)) {
            len = TOKEN_ARRAY[LEN] + 1
            tmp = substr(astr, 1, RLENGTH)
            gsub("\004", " ",   tmp)      # Unwrap
            gsub("\003", "",    tmp)      # Unwrap
            gsub("\002", "\"",  tmp)     
            gsub("\001", "\\",  tmp)      # Unwrap
            TOKEN_ARRAY[len] = tmp
            TOKEN_ARRAY[LEN] = len
            astr = substr(astr, RLENGTH+1)

        } else if ( match(astr, /^[^ \n\t\v\003]+/) ){ #"
            
            len = TOKEN_ARRAY[LEN] + 1
            tmp = substr(astr, 1, RLENGTH)
            gsub("\004", " ",       tmp)
            gsub("\003", "",        tmp)
            gsub("\002", "\"",      tmp)
            gsub("\001", "\\\\",    tmp)   # Notice different
            TOKEN_ARRAY[len] = tmp
            TOKEN_ARRAY[LEN] = len
            astr = substr(astr, RLENGTH+1)

            if ( match(astr, /^\003[^\003]+\003/) ) {
                tmp = substr(astr, 1, RLENGTH)
                gsub("\004", " ",   tmp)      # Unwrap
                gsub("\003", "",    tmp)      # Unwrap
                gsub("\002", "\"",  tmp)
                gsub("\001", "\\",  tmp)      # Unwrap
                TOKEN_ARRAY[len] = TOKEN_ARRAY[len] tmp

                astr = substr(astr, RLENGTH+1)
            }
        } else {
            panic_error("Fail to tokenzied following line:\n" original_astr "\n" astr)
        }

        astr = str_trim_left(astr)
    }
}

### Type check
function join_optarg_oparr(optarg_id, 
    len, idx, result, oparr_keyprefix){

    oparr_keyprefix = optarg_id KSEP OPTARG_OPARR

    result = ""
    len = option_arr[ oparr_keyprefix KSEP LEN ]
    for (idx=1; idx<=len; ++idx) {
        result = result " " option_arr[ oparr_keyprefix KSEP idx ]
    }

    return result
}

function assert_arr_eq(optarg_id, arg_name, value, sep,
    op_arr_len, i, idx, value_arr_len, value_arr, candidate, sw,
    oparr_keyprefix){

    oparr_keyprefix = optarg_id KSEP OPTARG_OPARR
    op_arr_len = option_arr[ oparr_keyprefix KSEP LEN ]

    value_arr_len = split(value, value_arr, sep)
    for (i=1; i<=value_arr_len; ++i) {
        sw = false
        for (idx=2; idx<=op_arr_len; ++idx) {
            candidate = option_arr[ oparr_keyprefix KSEP idx ]
            candidate = str_unquote_if_quoted( candidate )
            if ( value_arr[i] == candidate ) {
                sw = true
                break
            }
        }
        if (sw == false) {
            panic_error( "Arg: [" arg_name "] 's part of value is [" value_arr[i] "]\nFail to match any candidate:\n" join_optarg_oparr( optarg_id ) )
            print_helpdoc()
            exit_print(1)
        }
    }
}

function assert_arr_regex(optarg_id, arg_name, value, sep,
    i, value_arr_len, value_arr, sw, oparr_keyprefix){
    
    oparr_keyprefix = optarg_id KSEP OPTARG_OPARR

    len = option_arr[ oparr_keyprefix KSEP LEN ]

    value_arr_len = split(value, value_arr, sep)
    for (i=1; i<=value_arr_len; ++i) {
        sw = false
        for (idx=2; idx<=len; ++idx) {
            val = option_arr[ oparr_keyprefix KSEP idx ]
            val = str_unquote_if_quoted( val )
            if (match( value_arr[i], val )) {
                sw = true
                break
            }
        }
        if (sw == false) {
            panic_error( "Arg: [" arg_name "] 's part of value is [" value_arr[i] "]\nFail to match any regex pattern:\n" join_optarg_oparr( optarg_id ) )
            print_helpdoc()
            exit_print(1)
        }
    }
}

# op_arg_idx # token_arr_len, token_arr, op_arg_idx,         
function assert(optarg_id, arg_name, arg_val,
    op, sw, idx, len, val,
    oparr_keyprefix){

    oparr_keyprefix = optarg_id KSEP OPTARG_OPARR
    op = option_arr[ oparr_keyprefix KSEP 1 ]

    if (op == "=int") {
        if (! match(arg_val, /[+-]?[0-9]+/) ) {    # float is: /[+-]?[0-9]+(.[0-9]+)?/
            panic_error( "Arg: [" arg_name "] value is [" arg_val "]\nIs NOT an integer." )
            print_helpdoc()
            exit_print(1)
        }
    } else if (op == "=") {
        sw = false
        len = option_arr[ oparr_keyprefix KSEP LEN ]
        for (idx=2; idx<=len; ++idx) {
            val = option_arr[ oparr_keyprefix KSEP idx ]
            val = str_unquote_if_quoted( val )
            if (arg_val == val) {
                sw = true
                break
            }
        }
        if (sw == false) {
            panic_error( "Arg: [" arg_name "] value is [" arg_val "]\nFail to match any candidates:\n" join_optarg_oparr(optarg_id) )
            print_helpdoc()
            exit_print(1)
        }
    } else if (op == "=~") {
        sw = false
        len = option_arr[ oparr_keyprefix KSEP LEN ]
        for (idx=2; idx<=len; ++idx) {
            val = option_arr[ oparr_keyprefix KSEP idx ]
            val = str_unquote_if_quoted( val )
            if (match(arg_val, "^"val"$")) {
                sw = true
                break
            }
        }
        if (sw == false) {
            panic_error( "Arg: [" arg_name "] value is [" arg_val "]\nFail to match any regex pattern:\n" join_optarg_oparr(optarg_id) )
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
        # debug( "Op[" op "] Not Match any candidates: \n" line )
        exit_print(1)
        return false
    }

    return true
}

function arg_typecheck_then_generate_code(optarg_id, arg_var_name, arg_val,
    def, tmp ){

    # debug( "arg_typecheck_then_generate_code()\n " optarg_id "\t" arg_var_name )

    assert(optarg_id, arg_var_name, arg_val)
    append_code_assignment( arg_var_name, quote_string( arg_val ) )
}

###############################
# Step 1 Utils: Global types
###############################
BEGIN {
    type_arr[LEN]=0
}

function type_arr_add(line,                 name, rest){
    line = str_trim(line)

    match(line, /^[_\-A-Za-z0-9]+/)
    if (RLENGTH <= 0) {
        panic_error("Should not happned for type lines: \n" line)
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
    subcmd_arr[ LEN ]=0
    # subcmd_map

    # RS="\001"

    rest_option_id_list[ LEN ] = 0
}

BEGIN {
    option_arr[ LEN ]=0
    option_id_list[ LEN ] = 0

    # OPTION_ARGC = "num" # Equal LEN
    OPTION_SHORT = "shoft"
    OPTION_TYPE = "type"
    OPTION_DESC = "desc"

    OPTION_M = "M"
    OPTION_NAME = "varname"

    OPTARG_NAME = "val_name"
    OPTARG_TYPE = "val_type"
    OPTARG_DEFAULT = "val_default"
    
    OPTARG_DEFAULT_REQUIRED_VALUE = "\001"

    OPTARG_OPARR = "val_oparr"

    HAS_SUBCMD = -1
}

function handle_option_id(option_id,            arr, arr_len, arg_name, i, sw){

    # Add option_id to option_id_list
    i = option_id_list[ LEN ] + 1
    option_id_list[i] = option_id
    option_id_list[ LEN ] = i

    option_arr[ option_id KSEP OPTION_M ] = false

    arr_len = split( option_id, arr, /\|/ )

    # debug("handle_option_id \t" arr_len)
    for (i=1; i<=arr_len; ++i) {
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
        # debug( "option_alias_2_option_id\t" arg_name "!\t!" option_id "|" )
    }
}

# name is key_prefix like OPTION_NAME
function handle_optarg_declaration(optarg_definition, optarg_id,
    optarg_definition_token1, optarg_name, optarg_type, 
    default_value, tmp, type_rule, i ){

    # debug( "handle_optarg_definition:\t" optarg_definition )
    # debug( "optarg_id:\t" optarg_id )
    tokenize_argument_into_TOKEN_ARRAY( optarg_definition )
    optarg_definition_token1 = TOKEN_ARRAY[ 1 ]

    # debug( "handle_optarg_definition:\t" optarg_definition )
    # debug( "handle_optarg_declaration:\t" optarg_definition_token1 )

    if (! match( optarg_definition_token1, /^<[-_A-Za-z0-9]+>/) ) {
        panic_error("Unexecpted optarg declaration: \n" optarg_definition)
    }

    optarg_name = substr( optarg_definition_token1, 2, RLENGTH-2 )
        option_arr[ optarg_id KSEP OPTARG_NAME ] = optarg_name

    optarg_definition_token1 = substr( optarg_definition_token1, RLENGTH+1 )

    if (match( optarg_definition_token1, /^:[-_A-Za-z0-9]+/) ) {
        optarg_type = substr( optarg_definition_token1, 2, RLENGTH-1 ) 
        optarg_definition_token1 = substr( optarg_definition_token1, RLENGTH+1 )
    }

    if (match( optarg_definition_token1 , /^=/) ) {
        default_value = substr( optarg_definition_token1, 2 )
        option_arr[ optarg_id KSEP OPTARG_DEFAULT ] = str_unquote_if_quoted( default_value )
    } else {
        # It means, it is required.
        option_arr[ optarg_id KSEP OPTARG_DEFAULT ] = OPTARG_DEFAULT_REQUIRED_VALUE
    }

    if (TOKEN_ARRAY[ LEN ] >= 2) {
        for ( i=2; i<=TOKEN_ARRAY[ LEN ]; ++i ) {
            option_arr[ optarg_id KSEP OPTARG_OPARR KSEP (i-1) ] = TOKEN_ARRAY[i]
        }
        option_arr[ optarg_id KSEP OPTARG_OPARR KSEP LEN ] = TOKEN_ARRAY[ LEN ] - 1
    } else {
        type_rule = type_arr[ optarg_type ]
        if (type_rule == "") {
            # panic_error("Unknown type: \n" optarg_type)
            return
        }

        tokenize_argument_into_TOKEN_ARRAY( type_rule )

        for ( i=1; i<=TOKEN_ARRAY[ LEN ]; ++i ) {
            option_arr[ optarg_id KSEP OPTARG_OPARR KSEP i ] = TOKEN_ARRAY[i]
        }
        option_arr[ optarg_id KSEP OPTARG_OPARR KSEP LEN ] = TOKEN_ARRAY[ LEN ]
    }

}

function parse_param_dsl_for_positional_argument(line,
    option_id, option_desc, tmp){

    tokenize_argument_into_TOKEN_ARRAY( line )

    option_id = TOKEN_ARRAY[1]

    tmp = rest_option_id_list[ LEN ] + 1
    rest_option_id_list[ LEN ] = tmp
    rest_option_id_list[ tmp ] = option_id

    option_desc = TOKEN_ARRAY[2]
    option_arr[ option_id KSEP OPTION_DESC ] = option_desc

    if ( TOKEN_ARRAY[ LEN ] >= 3) {
        tmp = ""
        for (i=3; i<=TOKEN_ARRAY[LEN]; ++i) {
            tmp = tmp " " TOKEN_ARRAY[i]
        }

        option_arr[ option_id ] = tmp
        handle_optarg_declaration( tmp, option_id )
    }
}

function parse_param_dsl_for_all_positional_argument(line,
    option_id, option_desc, tmp){

    tokenize_argument_into_TOKEN_ARRAY( line )

    option_id = TOKEN_ARRAY[1]  # Should be #n

    tmp = rest_option_id_list[ LEN ] + 1
    rest_option_id_list[ LEN ] = tmp
    rest_option_id_list[ tmp ] = option_id

    option_desc = TOKEN_ARRAY[2]
    option_arr[ option_id KSEP OPTION_DESC ] = option_desc

    if ( TOKEN_ARRAY[ LEN ] >= 3) {
        tmp = ""
        for (i=3; i<=TOKEN_ARRAY[LEN]; ++i) {
            tmp = tmp " " TOKEN_ARRAY[i]
        }

        option_arr[ option_id ] = tmp
        handle_optarg_declaration( tmp, option_id )
    }
}

function parse_param_dsl(line,
    line_arr, i, j, state, tmp, len, nextline, subcmd,
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

        if (line == "") continue

        if (line ~ /^advise:/) {
            state = STATE_ADVISE
        } else if (line ~ /^type:/) {
            state = STATE_TYPE
        } else if (line ~ /^scope:/) {
            state = STATE_SCOPE
        } else if (line ~ /^option\s?:/) {
            state = STATE_OPTION
        } else if (line ~ /^subcommand\s?:/) {
            state = STATE_SUBCOMMAND
        } else if (line ~ /^argument\s?:/) {
            state = STATE_ARGUMENT
        } else {

            if (state == STATE_ADVISE) {
                tmp = advise_arr[ LEN ] + 1
                advise_arr[ LEN ] = tmp
                advise_arr[ tmp ] = line

            } else if ( state == STATE_TYPE ) {
                type_arr_add( line )

            } else if ( state == STATE_SUBCOMMAND ) {
                if (HAS_SUBCMD == false) {
                    panic_error("Subcommand and poisitional argument should not defined at the same time")
                }

                HAS_SUBCMD = true

                tmp = subcmd_arr[ LEN ] + 1
                subcmd_arr[ LEN ] = tmp

                if (! match(line, /^[A-Za-z0-9_-]+/)) {
                    panic_error( "Expect subcommand in the first token, but get:\n" line )
                }

                subcmd = substr( line, 1, RLENGTH )
                subcmd_arr[ tmp ] = subcmd
                subcmd_map[ subcmd ] = str_trim( substr( line, RLENGTH+1 ) )

            } else if (state == STATE_OPTION) {

                if ( match(line, /^\#n[\s]*/ ) )
                {
                    if (HAS_SUBCMD == true) {
                        panic_error("Subcommand and poisitional argument should not defined at the same time")
                    }
                    HAS_SUBCMD = false
                    parse_param_dsl_for_all_positional_argument( line )
                    continue
                }

                if ( match(line, /^\#[0-9]+[\s]*/) )
                {
                    if (HAS_SUBCMD == true) {
                        panic_error("Subcommand and poisitional argument should not defined at the same time")
                    }
                    HAS_SUBCMD = false
                    parse_param_dsl_for_positional_argument( line )
                    continue
                }

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

                j = 0
                if ( TOKEN_ARRAY[ LEN ] >= 3) {
                    tmp = ""
                    for (i=3; i<=TOKEN_ARRAY[LEN]; ++i) {
                        tmp = tmp " " TOKEN_ARRAY[i]
                    }

                    j = j + 1
                    option_arr[ option_id KSEP j ] = tmp
                    handle_optarg_declaration( tmp, option_id KSEP j )
                }

                while (true) {
                    i += 1
                    nextline = str_trim( line_arr[ i ] )
                    if ( nextline !~ /^</ ) {
                        i --
                        break
                    }
                    j = j + 1
                    option_arr[ option_id KSEP j ] = nextline
                    handle_optarg_declaration( nextline, option_id KSEP j )
                }

                option_arr[ option_id KSEP LEN ] = j
            }
        }
    }
}


###############################
# Step 3 Utils: Handle code
###############################

function check_required_option_ready(       i, j, option, option_argc, option_id, option_m, option_name ) 
{
    for (i=1; i<=option_id_list[ LEN ]; ++i) {
        option_id       = option_id_list[ i ]
        option_m        = option_arr[ option_id KSEP OPTION_M ]

        if ( option_arr_assigned[ option_id ] == true ) {
            if (option_m == true) {
                append_code_assignment( option_name "_n",    option_assignment_count[ option_id ] )
            }
            continue
        }

        option_argc      = option_arr[ option_id KSEP LEN ]

        if ( 0 == option_argc ) {
            continue
        }

        option_name     = option_arr[ option_id KSEP OPTION_NAME ]
        
        gsub(/^--?/, "", option_name)
        if ( true == option_m ) {
            append_code_assignment( option_name "_n", 1 )
            option_name = option_name "_" 1
        }

        # required?
        if (option_argc == 1) {
            val = option_default_map[ option_id ]
            if (length(val) == 0) {
                val = option_arr[ option_id KSEP 1 KSEP OPTARG_DEFAULT ]
            }

            if (val == OPTARG_DEFAULT_REQUIRED_VALUE) {
                panic_error("Required a value in option: " option_id " " 1)
            }

            # debug("requried : " val)
            assert(option_id KSEP 1, option_name, val)

            append_code_assignment( option_name, val )
            continue
        }

        # if argc >= 2
        for ( j=1; j<=option_argc; ++j ) {
            val = option_arr[ option_id KSEP j KSEP OPTARG_DEFAULT ]

            if (val == OPTARG_DEFAULT_REQUIRED_VALUE) {
                panic_error("Required a value in option: " option_id " " j)
            }

            assert(option_id KSEP 1, option_name "_" j, val)
            append_code_assignment( option_name "_" j, val )
        }
    }
    
}

###############################
# handle_arguments
###############################
function handle_arguments(          i, j, arg_name, arg_name_short, arg_val, option_id, option_argc, count, sw) {

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
                append_code_assignment( option_name, "true" )
            }
            continue
        }

        option_arr_assigned[ option_id ] = true

        option_argc     = option_arr[ option_id KSEP LEN ]
        option_m        = option_arr[ option_id KSEP OPTION_M ]
        option_name     = option_arr[ option_id KSEP OPTION_NAME ]
        gsub(/^--?/, "", option_name)

        # If option_argc == 0, op
        if (option_m == true) {
            if (option_assignment_count[ option_id ] != "") {
                counter = option_assignment_count[ option_id ] + 1
            } else {
                counter = 1
            }
            option_assignment_count[ option_id ] = counter
            option_name = option_name "_" counter
        }

        # Consider unhandled arguments are rest_argv
        if ( !( arg_name ~ /--?/ ) ) break
        
        if (option_argc == 0) {
            # print code XXX=true
            # debug( "handle_arguments " option_id "\t" option_name )
            append_code_assignment( option_name, "true" )
        } else if (option_argc == 1) {
            i = i + 1
            arg_val = arg_arr[i]
            if (i > arg_arr_len) {
                panic_error(i)
            }

            arg_typecheck_then_generate_code( option_id KSEP 1, 
                option_name, 
                arg_val)
        } else {
            for ( j=1; j<=option_argc; ++j ) {
                i += 1
                arg_val = arg_arr[i]
                if (i > arg_arr_len) {
                    panic_error(i)
                }

                arg_typecheck_then_generate_code( option_id KSEP j,
                    option_name "_" j,
                    arg_val)
            }
        }
        i += 1
    }

    check_required_option_ready()

    if (i > arg_arr_len) {
        append_code("set --")
        return
    }

    # if subcommand declaration exists
    # if (0 != subcmd_arr[LEN]) {
    if ( HAS_SUBCMD == true ) {
        if (subcmd_map[ arg_arr[i] ] == "") {
            panic_error("Subcommand expected, but not found: " arg_arr[i])
        }
        append_code_assignment( "PARAM_SUBCMD", arg_arr[i] )
        i += 1
    }

    for (j=i; j<=arg_arr_len; ++j) {
        tmp = tmp " " quote_string(arg_arr[j])
    }
    append_code("set -- " tmp)

    # if (0 == subcmd_arr[LEN]) {
    if ( HAS_SUBCMD == false ) {
        # We will do it only if subcommand not defined.
        for (j=i; j<=arg_arr_len; ++j) {
            tmp = option_arr[ "#" j ] # type
            if (tmp != "") {
                assert("#" i, "$" (j-i+1), arg_arr[j])
                continue
            }

            tmp = option_arr[ "#n" ] # type
            if (tmp != "") {
                assert("#n", "$" (j-i+1), arg_arr[j])
            }
        }
    }
}


NR==1 {
    type_arr_len = split(str_trim($0), type_arr, ARG_SEP)
    for (i=1; i<=type_arr_len; ++i) {
        if ( length( str_trim( type_arr[i] ) ) != 0 ) {
            # print i " " type_arr[i] >"/dev/stderr"
            type_arr_add(type_arr[i])
        }
    }
}


NR==2 {
    parse_param_dsl($0)
}

function print_helpdoc_getitem(oparr_keyprefix,
    op, oparr_string, op_arr_len, 
    k){

    op = option_arr[ oparr_keyprefix KSEP 1 ]
    if ( op == "" ) return ""

    oparr_string    = "<"
    op_arr_len = option_arr[ oparr_keyprefix KSEP LEN ]
    for ( k=2; k<=op_arr_len; ++k ) {
        oparr_string = oparr_string option_arr[ oparr_keyprefix KSEP k ] "|"
    }

    oparr_string = substr(oparr_string, 1, length(oparr_string)-1) ">"
    if (oparr_string == ">") oparr_string = ""

    return op "\t" oparr_string
}

function print_helpdoc(              i, j, k, option_id, option_argc, oparr_string, ret, HELP_DOC, key ){

    if (option_id_list[ LEN ] > 0 || rest_option_id_list[ LEN ] > 0) {
        HELP_DOC = HELP_DOC "Options:\n"    
    }

    for (i=1; i<=option_id_list[ LEN ]; ++i) {
        option_id       = option_id_list[ i ]
        option_argc     = option_arr[ option_id KSEP LEN ]

        HELP_DOC = HELP_DOC "  \033[36m" option_id "\t\033[91m" option_arr[option_id KSEP OPTION_DESC ] "\033[0m\n" 
        for ( j=1; j<=option_argc; ++j ) {
            oparr_keyprefix = option_id KSEP j KSEP OPTARG_OPARR
            oparr_string = print_helpdoc_getitem(oparr_keyprefix)
            if (oparr_string != "") HELP_DOC = HELP_DOC "    \033[35m" oparr_string "\033[0m\n"
        }
    }

    for (i=1; i <= rest_option_id_list[ LEN ]; ++i) {
        option_id       = rest_option_id_list[ i ]

        oparr_keyprefix = option_id KSEP OPTARG_OPARR
        oparr_string = print_helpdoc_getitem(oparr_keyprefix)
        HELP_DOC = HELP_DOC "  \033[36m" option_id "\t\033[35m" oparr_string " \t\033[91m" option_arr[option_id KSEP OPTION_DESC ] "\033[0m\n"
    }

    if (subcmd_arr[ LEN ]) {
        HELP_DOC = HELP_DOC "Subcommands:\n"
    }

    for (i=1; i <= subcmd_arr[ LEN ]; ++i) {
        key = subcmd_arr[ i ]
        HELP_DOC = HELP_DOC "  \033[36m" key "\t\033[91m" subcmd_map[ key ] "\033[0m\n" 
    }
    
    print "local HELP_DOC=" quote_string(HELP_DOC) " 2>/dev/null"
    print "printf %s " " " "\$HELP_DOC"
    print "return 0"
    exit_now(1)
}

function generate_advise_json_value_candidates(oparr_keyprefix,
    oparr_string, optarg_name, k, op ){

    op = option_arr[ oparr_keyprefix KSEP 1 ]

    oparr_string = ""
    if (op == "=") {
        op_arr_len = option_arr[ oparr_keyprefix KSEP LEN ]
        for ( k=2; k<=op_arr_len; ++k ) {
            oparr_string = oparr_string "\"" option_arr[ oparr_keyprefix KSEP k ] "\"" ", "
        }
        oparr_string = "[ " substr(oparr_string, 1, length(oparr_string)-2) " ],"
    } else if (op == "=~") {
        optarg_name = option_arr[ option_id KSEP OPTARG_NAME ]
        oparr_string = "[  ],"
        if ( advise_map[ optarg_name ] != "" ) {
            oparr_string = "\"" advise_map[ optarg_name ] "\","
            advise_map[ optarg_name ] = ""
        }
    } else {
        oparr_string = "[  ],"
    }

    return oparr_string
}

# Rely on subcmd_arr. Must after 
function generate_advise_json(      indent, indent_str,
    i, j, 
    option_id, option_argc, advise_map,
    option_id_advise, tmp ){
    indent = arg_arr[2] # for recursive gen advise json
    if (indent == "") indent = 0
    indent_str = ""
    for ( i=1; i <= indent; ++i ){
        indent_str = indent_str "  "
    }

    ADVISE_JSON = "{"

    for (i=1; i<=advise_arr[ LEN ]; ++i) { 
        split(advise_arr[ i ], tmp)

        for (j=2; j<=length(tmp); ++j) {
            advise_map[ tmp[1] ] = advise_map[ tmp[1] ] " " tmp[j]
        }
        advise_map[ tmp[1] ] = str_trim( advise_map[ tmp[1] ] )
    }

    for (i=1; i<=option_id_list[ LEN ]; ++i) {
        option_id       = option_id_list[ i ]
        option_argc     = option_arr[ option_id KSEP LEN ]

        if (option_argc == 0) {
            ADVISE_JSON = ADVISE_JSON "\n" indent_str "  \"" option_id "\": null,"
        }

        for ( j=1; j<=option_argc; ++j ) {
            oparr_keyprefix = option_id KSEP j KSEP OPTARG_OPARR
            oparr_string    = generate_advise_json_value_candidates(oparr_keyprefix)

            option_id_advise = option_id
            if (option_argc > 1) {
                option_id_advise = option_id_advise "|" j
            }
            ADVISE_JSON = ADVISE_JSON "\n" indent_str "  \"" option_id_advise "\": " oparr_string 
        }
    }

    for (i=1; i <= rest_option_id_list[ LEN ]; ++i) {
        option_id       = rest_option_id_list[ i ]
        oparr_keyprefix = option_id KSEP OPTARG_OPARR
        oparr_string    = generate_advise_json_value_candidates(oparr_keyprefix)
        ADVISE_JSON     = ADVISE_JSON "\n" indent_str "  \"" option_id "\": " oparr_string
    }

    for (key in advise_map) { 
        if ( advise_map[ key ] != "") {
            ADVISE_JSON = ADVISE_JSON "\n" indent_str "  \"" key "\": \"" advise_map[key] "\","
            # debug(key)
        }
    }

    for (i=1; i <= subcmd_arr[ LEN ]; ++i) {
        subcmd_funcname = "${X_CMD_ADVISE_FUNC_NAME}_" subcmd_arr[ i ]

        subcmd_invocation = "X_CMD_ADVISE_FUNC_NAME=${X_CMD_ADVISE_FUNC_NAME}_" subcmd_arr[ i ] " "
        subcmd_invocation = subcmd_invocation subcmd_funcname " _param_advise_json_items " (indent + 1) " 2>/dev/null "
        subcmd_invocation = "s=$(" subcmd_invocation "); "

        value = subcmd_invocation " if [ $? -eq 126 ]; then printf $s ; else printf 'null'; fi"
        value = "$( " value  " )"

        key = quote_string( subcmd_arr[ i ] )
        ADVISE_JSON = ADVISE_JSON "\n  " indent_str key ": " value ","
    }

    if (ADVISE_JSON != "{"){
        ADVISE_JSON = substr(ADVISE_JSON, 1, length(ADVISE_JSON)-1)
    }
    ADVISE_JSON = ADVISE_JSON "\n" indent_str "}"

    print "printf \"%s\" " quote_string(ADVISE_JSON)
    print "return 126"
}

NR==3 {
    # handle arguments
    arg_arr_len = split($0, arg_arr, ARG_SEP)
    arg_arr[ LEN ] = arg_arr_len

    if ( arg_arr[1] == "_param_list_subcmd" ) {
        for (i=1; i <= subcmd_arr[ LEN ]; ++i) {
            # debug( subcmd_arr[ i ] )
            print "printf \"%s\" " subcmd_arr[ i ]
        }
        print "return 0"
        exit_now(1)
    }

    if ( arg_arr[1] == "_param_advise_json_items" ) {
        generate_advise_json()
        exit_now(1)
    }    

    if ( "_param_help_doc" == arg_arr[1] )                              print_helpdoc()
    if ( "help" == arg_arr[1] ) {
        has_help_subcmd = false
        for (i=1; i <= subcmd_arr[ LEN ]; ++i) {
            if ( "help" == subcmd_arr[i] )  has_help_subcmd = true
        }
        if (has_help_subcmd == false)                                   print_helpdoc()
    }
    if ( ( "--help" == arg_arr[1] ) || ( "-h" == arg_arr[1] ) ) {
        if ("" == option_alias_2_option_id[ arg_arr[1] ])               print_helpdoc()
    }
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
    if (EXIT_CODE != 1) {
        handle_arguments()
        print_code()
        # debug(CODE)
    }
}
