function handle_option_argument_declaration(optarg_declaration, optarg_name,
    optarg_declaration, optarg_typename, optarg_type, 
    default_value, tmp, type_rule, i
    ){

    # optarg_declaration =>  meta  arg_type
    tokenize_argument_into_TOKEN_ARRAY( optarg_declaration )
    optarg_declaration = TOKEN_ARRAY[ 1 ]

    if (! match(def, /^<[-_A-Za-z0-9]+>/)) {
        panic_error("Unexecpted optarg declaration: \n" optarg_declaration)
    }

    optarg_typename = sub( optarg_declaration, 2, RLENGTH-1 )
    # TODO: rename OPTION_VAL_NAME
    option_arr[ optarg_name KSEP OPTION_VAL_NAME ] = optarg_typename

    optarg_declaration = sub( optarg_declaration, RLENGTH+1 )

    if (match( optarg_declaration, /^:[-_A-Za-z0-9]+/) ) {
        optarg_type = sub( optarg_declaration, 2, RLENGTH ) 
        optarg_declaration = sub( optarg_declaration, RLENGTH+1 )
    }

    if (match( optarg_declaration , /^=/) ) {
        default_value = sub( optarg_declaration, 2 )
        option_arr[ optarg_name KSEP OPTION_VAL_DEFAULT ] = str_unquote_if_quoted( default_value )
    } else {
        # It means, it is required.
        option_arr[ optarg_name KSEP OPTION_VAL_DEFAULT ] = OPTION_VAL_DEFAULT_REQUIRED_VALUE
    }

    if (TOKEN_ARRAY[ LEN ] >= 2) {
        for ( i=2; i<=TOKEN_ARRAY[ LEN ]; ++i ) {
            option_arr[ optarg_name KSEP OPTION_VAL_OPARR KSEP (i-1) ] = TOKEN_ARRAY[i]
        }
        option_arr[ optarg_name KSEP OPTION_VAL_OPARR KSEP LEN ] = i - 2
    } else {
        type_rule = type_arr[ optarg_type ]
        if (type_rule == "") {
            panic_error("Unknown type: \n" optarg_type)
        }

        tokenize_argument_into_TOKEN_ARRAY( type_rule )

        for ( i=1; i<=TOKEN_ARRAY[ LEN ]; ++i ) {
            option_arr[ optarg_name KSEP OPTION_VAL_OPARR KSEP i ] = TOKEN_ARRAY[i]
        }
        option_arr[ optarg_name KSEP OPTION_VAL_OPARR KSEP LEN ] = i - 1
    }

}