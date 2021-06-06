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
function tokenize_argument(astr,
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
            astr = substr(option, RLENGTH+1)

        } else if (match(/^[^ \t\v]+/), astr){
            len = TOKEN_ARRAY[LEN] + 1
            tmp = substr(astr, 1, RLENGTH)
            gsub("\004", tmp, " ")
            gsub("\003", tmp, "")
            gsub("\002", tmp, "\"")
            gsub("\001", tmp, "\\\\")   # Notice different
            TOKEN_ARRAY[len] = tmp
            TOKEN_ARRAY[LEN] = len
            astr = substr(option, RLENGTH+1)
        } else {
            panic_error("Fail to tokenzied following line:\n" original_astr)
        }

        astr = str_trim_left(astr)
    }
}

### Type check
function assert_arr_eq(rule_line, arg_name, value, sep, op_arr,
    i, idx, value_arr_len, value_arr, sw){

    value_arr_len = split(value, value_arr, sep)
    for (i=1; i<=value_arr_len; ++i) {
        sw = false
        for (idx=2; idx<=op_arr[LEN]; ++idx) {
            if (value_arr[i] == op_arr[idx]) {
                sw = true
                break
            }
        }
        if (sw == false) {
            error( "Arg: [" arg_name "] 's part of value is [" value_arr[i] "]\nFail to match any candidate:\n" rule_line )
            print_helpdoc()
            exit_print(1)
        }
    }
}

function assert_arr_regex(rule_line, arg_name, value, sep, op_arr,
    i, value_arr_len, value_arr, sw){

    value_arr_len = split(value, value_arr, sep)
    for (i=1; i<=value_arr_len; ++i) {
        sw = false
        for (idx=2; idx<=op_arr[LEN]; ++idx) {
            if (match(value_arr[i], op_arr[idx])) {
                sw = true
                break
            }
        }
        if (sw == false) {
            error( "Arg: [" arg_name "] 's part of value is [" value_arr[i] "]\nFail to match any regex pattern:\n" rule_line )
            print_helpdoc()
            exit_print(1)
        }
    }
}

# op_arg_idx # token_arr_len, token_arr, op_arg_idx,         
function assert(rule_line, arg_name, arg_val, op_arr,
    op, sw, idx){

    op = op_arr[1]
    if (op == "=int") {
        if (! match(arg_val, /[+-]?[0-9]+/) ) {    # float is: /[+-]?[0-9]+(.[0-9]+)?/
            error( "Arg: [" arg_name "] value is [" arg_val "]\nIs NOT an integer." )
            print_helpdoc()
            exit_print(1)
        }
    } else if (op == "=") {
        sw = false
        for (idx=2; idx<=op_arr[LEN]; ++idx) {
            if (arg_val == op_arr[idx]) {
                sw = true
                break
            }
        }
        if (sw == false) {
            error( "Arg: [" arg_name "] value is [" arg_val "]\nFail to match any candidates:\n" rule_line )
            print_helpdoc()
            exit_print(1)
        }
    } else if (op == "=~") {
        sw = false
        for (idx=2; idx<=op_arr[LEN]; ++idx) {
            if (match(arg_val, "^"op_arr[idx]"$")) {
                sw = true
                break
            }
        }
        if (sw == false) {
            error( "Arg: [" arg_name "] value is [" arg_val "]\nFail to match any regex pattern:\n" rule_line )
            print_helpdoc()
            exit_print(1)
        }

    } else if (op ~ /^=.$/) {
        sep = substr(op, 2, 1)
        assert_arr_eq(rule_line, arg_name, arg_val, sep, op, op_arr)
    } else if (op ~ /^=~.$/) {
        sep = substr(op, 3, 1)
        assert_arr_regex(rule_line, arg_name, arg_val, sep, op, op_arr)
    } else {
        print "Op[" op "] Not Match any candidates: \n" line > "/dev/stderr"
        exit_print(1)
        return false
    }

    return true
}

function typecheck(arg_val, arg_rule,
    len, i, token) {

    tokenize_argument(arg_rule)
    for (i=1; i<=len; ++i) {
        assert(arg_rule, arg_name, arg_val, TOKEN_ARRAY)
    }
}

function arg_typecheck_then_generate_code(arg_var_name, arg_val, argtype){
    if (argtype ~ /^=/) {
        typecheck(arg_val, argtype)
    } else {
        typecheck(arg_val, type_arr[argtype])
    }

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
# Step 2 Utils: Parse param dsl
###############################

BEGIN {
    advise_arr[LEN]=0
    option_arr[LEN]=0

    arg_arr[LEN]=0

    subcommand_arr[LEN]=0

    rest_argv_arr[LEN]=0
    # argument_detail_arr

    OPTION_ARGC = "ARGC"

    RS="\001"
}

function parse_param_dsl(line,
    line_arr, i, j, state, tmp) {

    state = 0
    STATE_ADVISE        = 1
    STATE_TYPE          = 2
    STATE_DEFAULT       = 3
    STATE_OPTION        = 4
    STATE_SUBCOMMAND    = 5
    STATE_ARGUMENT      = 6

    line_arr_len = split(line, line_arr, "\n")

    for (i=1; i<=line_arr_len; ++i) {
        line = line_arr[i]

        line = str_trim(line)

        if (line ~ /^advise:/) {
            state = STATE_ADVISE
        } else if (line ~ /^type:/) {
            state = STATE_TYPE
        } else if (line ~ /^default:/) {
            state = STATE_DEFAULT
        } else if (line ~ /^option\s:\s+/) {
            state = STATE_OPTION
        } else if (line ~ /^subcommand\s:\s+/) {
            state = STATE_SUBCOMMAND
        } else if (line ~ /^argument\s:\s+/) {
            state = STATE_ARGUMENT
        } else {

            if (state == STATE_ADVISE) {
                tmp = advise_arr[LEN] + 1
                advise_arr[LEN] = tmp
                advise_arr[tmp] = line

            } else if (state == STATE_OPTION) {
                # TODO: if multiple options: merge.

                # Parsing happened here.

                if (line !~ /^-/) {
                    panic_error("Expect option starting with - or -- :\n" line)
                }

                j = i

                while (true) {
                    nextline = line[++j]
                    if ( str_trim(line[++j]) !~ /^-/ ) {

                    }
                }
                
                tmp = option_arr[LEN] + 1
                option_arr[LEN] = tmp
                option_arr[tmp] = line

                option_arr[tmp KSEP 1]
                option_arr[tmp KSEP 2]

            } else if (state == STATE_TYPE) {
                type_arr_add(line)

            } else if (state == STATE_SUBCOMMAND) {
                tmp = subcommand_arr[LEN] + 1
                subcommand_arr[LEN] = tmp
                subcommand_arr[tmp] = line

            } else if (state == STATE_ARGUMENT) {
                tmp = rest_argv_arr[LEN] + 1
                rest_argv_arr[LEN] = tmp
                rest_argv_arr[tmp] = line
            }

        }
    }
}


###############################
# Step 3 Utils: Handle code
###############################

BEGIN{
    OPTION_NUM = "num"
    OPTION_SHORT = "shoft"
    OPTION_TYPE = "type"
    OPTION_DESC = "desc"
}

# Good.
function parse_into_OPTION_DETAIL(option,
    tmp, arr){
    option = "--repo|-r       \"Provide repo name\"     <repo>:repo_type=\"\"   "

    gsub("\\\\", option, "\001")
    gsub("\\\"", option, "\002")
    gsub("\"", option, "\003")
    
    if (! match(/--[^ ]+[ ]+/), option){
        panic_error("error in match")
    }
    
    option_name = substr(option, 1, RLENGTH)
    option = substr(option, RLENGTH+1)

    arr[LEN] = 0
    
    while (1) {
        if (match(/[^\"]+[ ]+/), option) #"
        {
            tmp = substr(option, 1, RLENGTH)
            option = substr(option, RLENGTH+1)
            len = arr[LEN]
            arr[LEN] = len + 1
            arr[len] = tmp
        } else if (match(/[^\"]+=/, option)) #"
        {
            tmp = substr(option, 1, RLENGTH)
            option = substr(option, RLENGTH+1)
            if (match(/\"[^"]\"/, option))  #"
            {
                tmp = tmp substr(option, 1, RLENGTH)
                option = substr(option, RLENGTH+1)
            }
        } else {
            panic_error("Fail to parse option")
        }        
    }

}


###############################
# handle_arguments
###############################
function handle_arguments(   
    i, j, argname, arg_val, option_name, option_num, count){

    arg_arr_len = arg_arr[LEN]

    i = 1
    while (i <= arg_arr_len) {
        argname = arg_arr[i]

        option_name     = option_arr[argname]

        parse_into_OPTION_DETAIL( option_arr[option_name] )
        option_num      = OPTION_DETAIL[OPTION_NUM]
        option_m        = OPTION_DETAIL[OPTION_M]

        arg_var_name    = argname

        if (option_m == true) {
            counter = (arg_count[argname] || 0) + 1
            arg_count[argname] = counter
            arg_var_name = arg_var_name "_" counter
        }

        # Consider unhandled arguments are rest_argv
        if ( !( argname ~ /--?/ ) ) break
        
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
                arg_var_name, 
                arg_val, 
                OPTION_DETAIL[OPTION_TYPE] 
            )
        } else {
            for (j=1; j<=option_num; ++j) {
                i += 1
                arg_val = arg_arr[i]
                if (i > arg_arr_len) {
                    panic_error(i)
                }

                arg_typecheck_then_generate_code( 
                    arg_var_name "_" j,
                    arg_val,
                    OPTION_DETAIL[OPTION_TYPE j] 
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
