# shellcheck shell=sh disable=SC2039,SC2142,SC3043

w() {
    local arg1
    local arg2
    local arg3
    local arg_sep
    local dict_sep
    arg1=$(param_default get "gitee/$O" arg1)
    arg2=$(param_default get "gitee/$O" arg2)
    arg3=$(param_default get "gitee/$O" arg3)

    assert_stdout "param_default dump gitee/$O" <<A
{
  "arg1": "1",
  "arg2": "11",
  "arg3": "111"
}
A
    arg_sep="$(printf "\005")" 
    assert_stdout "param_default dump gitee" <<A
{
  "c${arg_sep}arg1": "1",
  "c${arg_sep}arg2": "11",
  "c${arg_sep}arg3": "111"
}
A
    dict_sep="$(printf "\003")"
    assert_stdout "param_default dump_raw gitee/$O" <<A
c${arg_sep}arg1${dict_sep}1${dict_sep}c${arg_sep}arg2${dict_sep}11${dict_sep}c${arg_sep}arg3${dict_sep}111${dict_sep}3
A
    # TODO: 有疑问
    assert_stdout "param_default dump_raw gitee"  <<A
c${arg_sep}arg1${dict_sep}1${dict_sep}c${arg_sep}arg2${dict_sep}11${dict_sep}c${arg_sep}arg3${dict_sep}111${dict_sep}3
A
}

param_default put gitee/c arg1 1
param_default put gitee/c arg2 11
param_default put gitee/c arg3 111

ff() {
    O=c w -a private --repo "中文" --user "7777" work a b
}

ff