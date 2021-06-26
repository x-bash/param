# shellcheck shell=sh disable=SC2039,SC2142,SC3043,SC1090

    # ./testcases/v1.test.default.sh
    # ./testcases/v1.test.advise.rest.sh
    # ./testcases/v1.test.advise.subcmd.sh
    # ./testcases/v1.test.list.sh
    # ./testcases/v1.test.rest.sh

testcase_list="
    ./testcases/v1.test.subcmd.sh
    
"

. ./v1
xrc assert

for testcase in $testcase_list 
do
    printf "\n====== test %s =====\n" "$testcase"
    . "${testcase}"
    printf "\n=====================\n"
done


# TODO 需要解决的问题
# 1. dict 的各个版本之前的差异还是有问题 ./v1 L16
# 2. 合并一个更优雅的testcase, 更充分的 testcase
# 3. advise 的内容生成生成，递归调用 param
# 4. help 文档生成
