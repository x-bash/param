


```bash

param typedef repo-type =~ [A-Za-z0-9]+
param typedef user-type =~ [A-Za-z][A-Za-z0-9_]+

param new gitee.param # param make gitee; O=gitee param
# alias gitee.param="O=gitee param"


gitee.param default set "key" "value"
gitee.param default set "a" "b"

gitee.param typedef repo-type =~ [A-Za-z0-9]+


# param => cmd
# param.def

# gitee.param
# gitee.param

param new gitee.param

create_repo(){

    gitee.param default     "$O"
    gitee.param typdef      repo_type =~ [A-Za-z0-9]+

    gitee.param.def <<A
OPTIONS:
    --repo|-r   <repo name>=""                              "Provide repo name"
        > list_repo
    --repo|-r   <repo name>:repo_type=""        "Provide repo name"
        > list_repo

Subcommand:
    repo

Arguments:
    #1      <repo name>=""          "Repo Name"
        > list_repo
    #n      <repo name>=""          "Repo Name"
A


    eval "$PARAM_SUBCMD"

}


```



```bash
param typedef repo-type =~ [A-Za-z0-9]+
param typedef user-type =~ [A-Za-z][A-Za-z0-9_]+


# param_default github
param_typedef repo_type =~ [A-Za-z0-9]+

param create_repo github <<A
--repo|-r   <repo name>=""       "Provide repo name"
--repo|-r   <repo name>:create_repo_repo_type=""       "Provide repo name"
A

create_repo(){

    

}


```

