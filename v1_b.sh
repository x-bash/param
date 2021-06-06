

a_n=3

a_1=3
a_2=2
a_3=1

param_marg(){
    local a=${1:?Provide argument name}
    local n=${2:?Provide argument name}
    eval "echo \"\$${a}_${n}\""
}

param_marg_len(){
    local a=${1:?Provide argument name}
    eval "echo \"\$${a}_n\""
}





b_n=3

b_1_1=3
b_1_2=3

b_2_1=2
b_2_2=2

b_3_1=1
b_3_2=1


param_marg(){
    local a=${1:?Provide argument name}
    local n=${2:?Provide argument name}
    if [ -z "$3" ]; then
        eval "echo \"\$${a}_${n}\""
    else
        eval "echo \"\$${a}_${n}_${3}\""
    fi
}

param_marg_len(){
    local a=${1:?Provide argument name}
    eval "echo \"\$${a}_n\""
}

param_marg b 1 2

repo_1

list split "," "asf" a
for i in $(a index); do
    a get "$i"
done




