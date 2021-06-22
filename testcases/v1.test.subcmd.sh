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
    --priviledge|-p       "Provide privilidge"
        <priviledge_type>:access=public
subcommand:
    repo            ""
    user            ""
A

    echo "param repo: $repo"
    echo "param repo2: $repo2_n  $repo2_1_1 $repo2_1_2"
    echo "param priviledge: $priviledge"
    echo "help doc : $HELP_DOC"

    work_${PARAM_SUBCMD} "$*"
}

work_repo(){
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
    --priviledge|-p       "Provide privilidge"
        <priviledge_type>:access=public
subcommand:
    repo2            ""
    user            ""
A

    echo "work_repo()"
}

work_user(){
    echo "work_user"
}

work --repo abc -r2 abc cde repo
work _param_help_doc
work _param_advise_json_items
work_user _param_advise_json_items



