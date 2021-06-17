# shellcheck shell=sh disable=SC2039,SC2142,SC3043,SC1090

testcase_list="
    ./testcases/v1.test.advise.rest.sh
    ./testcases/v1.test.advise.subcmd.sh
    ./testcases/v1.test.list.sh
    ./testcases/v1.test.subcmd.sh
"

for testcase in $testcase_list 
do
    printf "\n====== test %s =====\n" "$testcase"
    . "${testcase}"
    printf "\n=====================\n"
done


# TODO 需要解决的问题
# 1. dict 的各个版本之前的差异还是有问题，
# 2. 

w() {

    echo "-------"
    local arg1
    local arg2
    local arg3
    arg1=$(param_default get "gitee/$O" arg1)
    arg2=$(param_default get "gitee/$O" arg2)
    arg3=$(param_default get "gitee/$O" arg3)

    # param_default dump
    param_default dump "gitee/$O" && echo
    param_default dump "gitee" && echo  # TODO: 这个跑不到

    # param_default dump
    param_default dump_raw "gitee/$O" && echo
    param_default dump_raw "gitee" && echo  # TODO: 这个跑不到

param <<A
scope:
    gitee   $O
type:
    access  =   private         public
advise:
    repo list_repo
    1: list_repo
option:
    --repo|-r|m         "Provide repo name"
        <repo>:repo_type                =~   "abc"   "cde"   "def"
    --repo2|-r2|m       "Provide two repo name"
        <repo1>
        <repo2>:repo_type               =~   "abc"   "cde"   "def"
    --repo|-r|m     "Provide repo name"
        <repo>:repo_type                =~   "abc"   "cde"   "def"
    --repo|-r|m     "Provide repo name"
        <repo>:repo_type="el's repo"    =~   "abc"   "cde"   "def"
subcommand:
    repo            ""
    user            ""
A

    echo "-------"
    echo "arg1: $arg1"
    echo "arg2: $arg2"
    echo "arg3: $arg3"
}

# param_default clear gitee___c
param_default put gitee/c arg1 1
param_default put gitee/c arg2 11
param_default put gitee/c arg3 111

ff() {
    O=c w -a private --repo "中文" --user "7777" work a b
}

ff
