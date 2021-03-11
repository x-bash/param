
xrc param/v0
# . "./v0"

########

# PARAM_ARGS=$li
# $@

# gitee.repo.create -a public a1 a2 a3

w(){
    echo "-------"
    param_default get "gitee_$O" repo
    echo "-------"

    param <<A
    default     gitee___$O
    --repo      "Provide repo name"             =~      [A-Za-z0-9\n]+
    --user=el   -u  "Provide user name"         =~      [A-Za-z0-9]+
    --access    -a  "Access Priviledge"         =       public private
    --verbose   -v  "Display in verbose mode"   =FLAG
    #1          =~      [A-Za-z0-9\n]+
    ...         =~      [A-Za-z0-9\n]+
A

    echo "----"

    echo "repo: $repo"
    echo "user: $user"
    echo "access: $access"
    echo "verbose: $verbose"

    echo "Other arguments:    $*"
    echo "$HELP_DOC"
}

param_default clear gitee___c
param_default put   gitee___c repo xk1
O=c w -a private hi

# w --repo hi

ff(){
    O=OBJECT_NAME w -a private --repo "asfasfd
asdfaf" work a b
}

ff
