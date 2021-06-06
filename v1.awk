

# OPTION_DETAIL


function panic_error(msg){
    print msg > "/dev/stderr"
}

function print_code(code){
    print code
}

function handle_arg_each(){
    # handle multiple arguments
    # handle argument_1

    # TODO: parse value
    # TODO: type check
    # TODO: print code
}

BEGIN{

    LEN="len"
    TOKEN_SEP = "\n"

    advise_arr[LEN]=0
    option_arr[LEN]=0

    type_arr[LEN]=0
    arg_arr[LEN]=0

    # arg_default_map

    default_scope = ""
    default_filelist = ""

    subcommand_arr[LEN]=0

    rest_argv_arr[LEN]=0
    # argument_detail_arr

    RS="\001"
}

# output certain kinds of array


function str_trim(astr){
    gsub(/^[ \t\b\v\n]+/, "", astr)
    gsub(/[ \t\b\v\n]+$/, "", astr)
    return astr
}

###############################
# Line 1: Global types
###############################

function handle_type_lines(line,
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

NR==1{
    type_arr_len = split($0, type_arr, /[ \t\v]+/)
    for (i=1; i<=type_arr_len; ++i) {
        handle_type_lines(type_arr[i])
    }
}

###############################
# Line 2: Config lines
###############################

function handle_config_lines(line,
    line_arr, i, state, tmp) {

    state = 0
    STATE_ADVISE = 1
    STATE_TYPE = 2
    STATE_DEFAULT = 3
    STATE_OPTION = 4
    STATE_SUBCOMMAND = 5
    STATE_ARGUMENT = 6

    line_arr_len = split(line, line_arr, "\n")

    for (i=1; i<=line_arr_len; ++i) {
        line = line_arr[i]

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
                tmp = option_arr[LEN] + 1
                option_arr[LEN] = tmp
                option_arr[tmp] = line
                option_arr[tmp "\034" 1]
                option_arr[tmp "\034" 2]

            } else if (state == STATE_TYPE) {
                tmp = type_arr[LEN] + 1
                type_arr[LEN] = tmp
                type_arr[tmp] = line

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


BEGIN{
    OPTION_NUM = "num"
    OPTION_SHORT = "shoft"
    OPTION_TYPE = "type"
    OPTION_DESC = "desc"
}

# Good.
function parse_to_OPTION_DETAIL(option,
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
            tmp = substr(option, 1, RLENGH)
            option = substr(option, RLENGTH+1)
            if (match(/\"[^"]\"/, option))  #"
            {
                tmp = tmp substr(option, 1, RLENGH)
                option = substr(option, RLENGTH+1)
            }
        } else {
            panic_error("Fail to parse option")
        }        
    }

}


NR==2{
    handle_config_lines($0)
    # analyze option line

    # analyze subcommand lines
}


NR==3{
    # handle arguments
    split($0, arg_arr, ARG_SEP)
}


###############################
# Line 4: Defaults As Map
###############################

NR>=4{
    if (keyline == "") {
        keyline = $0
    } else {
        arg_default_map[keyline] = $0
        keyline = ""
    }
}


###############################
# handle_arguments
###############################
function handle_arguments(
    i, arg, option_name, option_num,
    j){

    arg_arr_len = arg_arr[LEN]

    i = 1
    while (i <= arg_arr_len) {
        arg = arg_arr[i]

        option_name = option_arr[arg]
        parse_to_OPTION_DETAIL(option_arr[option_name])
        option_num = OPTION_DETAIL[OPTION_NUM]

        # option
        if ( !( arg ~ /--?/ ) ) break
        
        if (option_num == 0) {
            # OK, enable
            # print code XXX=true
        } else if (option_num == 1) {
            i = i + 1
            argval = arg_arr[i]
            if (i > arg_arr_len) {
                panic_error(i)
            }
            handle_arg_each( "", arg, type_rule )
        } else {
            for (j=1; j<=option_num; ++j) {
                i += 1
                if (i > arg_arr_len) {
                    panic_error(i)
                }
                handle_arg_each( j, arg, type_rule )
            }
        }
        i += 1
    }

    if (i <= arg_arr_len) {
        # handle rest argv
        # TODO: print code set -- arguments

        # TODO: typecheck the argument value

    } else {
        print_code("set --")
    }
}

END{
    handle_arguments()
}


