# shellcheck shell=sh disable=SC2039,SC2142,SC3043

. ~/.x-cmd/boot

. ./v1

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
    --priviledge|-p       "Provide privilidge"
        <priviledge_type>:access=public
    #n  "Provide repos" <repo_name>:repo_t

A

# subcommand:
#     repo            ""
#     user            ""

    echo "param repo: $repo"
    echo "param repo2: $repo2_n  $repo2_1_1 $repo2_1_2"
    echo "param priviledge: $priviledge"

    # work_${PARAM_SUBCMD} "$*";
    echo "$*"
}

work_repo(){
    echo "work_repo()"
}

work_user(){
    echo "work_user"
}

work --repo abc -r2 abc cde cde
