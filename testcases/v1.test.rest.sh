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
type:
    access  =   private         public
    repo_t  =~   "cde"   "def"
advise:
    repo list_repo
    1: list_repo
option:
    --repo|-r           "Provide repo name"
        <repo>:repo_type                =~   "abc"   "cde"   "def"
    --repo2|-r2|m       "Provide two repo name"
        <repo1>:repo_type               =~   "abc"   "cde"   "def"
        <repo2>:repo_t
    --user|-u           "User name"
        <user>:user
    --priviledge|-p     "Provide privilidge"
        <priviledge_type>:access=public
    --debug             "Open debug mode"
    #n  "Provide repos" <repo_name>:repo_t

A

    echo "param repo: $repo"
    echo "param repo2: $repo2_n  $repo2_1_1 $repo2_1_2"
    echo "param priviledge: $priviledge"
    echo "debug: $debug "

    # work_${PARAM_SUBCMD} "$*";
    echo "$*"
}

work_repo(){
    echo "work_repo()"
}

work_user(){
    echo "work_user"
}

work --repo abc --debug -u niracler -r2 abc cde cde 
work _param_help_doc