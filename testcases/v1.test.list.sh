# shellcheck shell=sh disable=SC2039,SC2142,SC3043

param_type_unset    gitee

# Using alias
# param_type    gitee     repo
param_type    gitee     user    =~  [A-Za-z0-9_]+
param_type    gitee     access  =   private         public          inner-public

work(){
    param <<A
scope:
    gitee   $O
subcommand:
    repo            ""
    user            ""
A
}

work_repo(){
    echo "work_repo()"
}

work_user(){
    echo "work_user"
}

assert_stdout "work _param_list_subcmd" <<A
repouser
A