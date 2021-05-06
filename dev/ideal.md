

```bash

# Ideal design

gitee(){
    param_default gitee $O
    param <<A
OPTIONS:
    --help|-h <section name>        "Provide repo name"
    --debug|-D                      "Open DEBUG"

SUBCOMMANDS:
    repo    "repo command"
    user    "user command"
A

    if [ $debug ]; then
        :
    fi
}

```


```bash

# Ideal design

# First argument is gitee function
# Second and third argument is options for default.

param_gen gitee gitee $O <<A
OPTIONS:
    --help|-h <section name>        "Provide repo name"
    --debug|-D                      "Open DEBUG"

SUBCOMMANDS:
    repo    "repo command"
    user    "user command"
"
A


gitee_param(){
    if [ $debug ]; then
        :
    fi
}

```
