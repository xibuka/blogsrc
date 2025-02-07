---
title: "Secure deployment Kong Gateway using Mozila SOPS, age and Github Action"
date: 2023-03-09T16:41:18+09:00
draft: false
tags:
- Kong
- Security
---

## Background

When deploying Kong Gateway, there is some data that we do not want to store in plain text, such as connection information to the database. The Kong Secret Manager was developed to solve this problem, which can be solved using a 3rd party service such as AWS Secrets Manager. However, this functionality is unavailable when the environment does not allow connection to external security services. In this case, we can use a encryption tool SOPS, developed by Mozilla to do the encryption and decryption. And also we can make the deploy process into the CI/CD workflow (e.g. Github Action) to make the decrypted configuration file only existing in a temproray workflow.

## Preparation

First, let's try to do the encryption and decryption in a local environment. Install the following necessary tools in your local environment.

1. [age](https://github.com/FiloSottile/age/releases)
2. [sops](https://github.com/mozilla/sops/releases)

SOPS is a handy and popular encryption/decryption tool, supporting PGP, age, Google cloud's KMS, Azure's key vault, Hashicorp Vault, etc. We chose age because we intend to use other cloud services as little as possible.
Once you have installed the tools, try `age-kengen --help`.

```bash
$ age-keygen --help
Usage:
    age-keygen [-o OUTPUT]
    age-keygen -y [-o OUTPUT] [INPUT]

Options:
    -o, --output OUTPUT       Write the result to the file at path OUTPUT.
    -y                        Convert an identity file to a recipients file.
```

Since it looks OK, let's generate the key.

## generate key

```bash
$ age-keygen -o sops-key.txt
Public key: age1hhpnj4ylj5z7qwaek0ncrq882ygmvnv4unup78u3djgmlezrmgkqshyatc
$ cat sops-key.txt
# created: 2023-03-08T06:07:28Z
# public key: age1hhpnj4ylj5z7qwaek0ncrq882ygmvnv4unup78u3djgmlezrmgkqshyatc
AGE-SECRET-KEY-1UHJNXS6RKYWA72RVED0ERGZVQ98N6MDFV6Y3CSPPN9JKLKSRH9GSQRLFAE`
```

Two keys have been generated in the `sops-key.txt` file: The public key for encryption and the Private key for decryption.

## Encryption of configuration file

To use SOPS more conveniently, let's create a single configuration file, `.sops.yaml`. You no longer need to specify the key from the command line; enter the Public key you just generated after `age`, and the `encrypted_regex` part is where you set which sections of the contents to encrypt.

``` yaml
creation_rules:
  - encrypted_regex: '^(env|admin|proxy|enterprise|manager|portal|portalapi|postgresql)$'
    age: age1hhpnj4ylj5z7qwaek0ncrq882ygmvnv4unup78u3djgmlezrmgkqshyatc
```

The following command will encrypt the files in the Kong GW deployment with the above configuration. Parameter `-e` means encrypt, and `-i` means save the changes to the orignal file.

``` bash
$ sops -e -i values.yaml
$ head values.yaml
image:
    repository: kong/kong-gateway
    tag: "3.1"
env:
    prefix: ENC[AES256_GCM,data:2AFF90x0Q3Ej9cMDiw==,iv:o/jBUcZIypUEioKk0Fd4uheBrCOlUOL4RQYExOW696E=,tag:LoIjejClr7lh37Rq9YeKDw==,type:str]
    log_level: ENC[AES256_GCM,data:ZhYxI6A=,iv:oZJ8E/MocmOonUPD2FY6BLaXPuj4TBl//0fqTmOY0Xg=,tag:46p/kxlNSctmOGFupQSnOQ==,type:str]
    database: ENC[AES256_GCM,data:3L8H1aqImEc=,iv:9iF+73VeFWbsmHqW1yKBCgwMpO3us8pTWwSWmNaCl80=,tag:icNvo+EvoYnxiAGdjxzPqw==,type:str]
    proxy_url: ENC[AES256_GCM,data:89WLCtCUglsyZQdsns1Lj6O/CI6YtCc8wXdX9EIJCGNwzmjB8v8=,iv:HUFPH8bgG62UvAeQATh/0GprR8zOgLBGmvcYbON4B00=,tag:Q1l7E8l5xClp52KSEz+MNQ==,type:str]
    admin_gui_url: ENC[AES256_GCM,data:Xun4V7eliBRlmfn8v3CVFwxMjRumh+REwmPgCDbWwrPhjSQMXkn6qQ==,iv:8zH3GjO35ycpAsuOgDB+UKNAc19zSee72z2UlrdZ+Js=,tag:U4IEK5Nef6h59vbHyM0aSA==,type:str]
    admin_api_uri: ENC[AES256_GCM,data:52j0JgFNldx5Qytsqav9nSLLLEUzR7+KsNo8aTsjbS2IyTM1R00=,iv:0RkBMi8k/XhuEzGSRpIQ9VQGbcUOTcb+o/KUVJ5LSYk=,tag:m5o89fI+GCKxD7TcLf5Nqg==,type:str]
```

The `image` section is not in the `encrypted_regex` filed, so it is left in plain text.

## Decrypt the configuration file

First, we need to copy the Private Key to `.config/sops/age/keys.txt`. This is the default path of the private key, so you will not need to specify the Private Key when executing the sops command. Once the Private Key is set, you can compound the file encrypted above with the following command. Similar to the above, parameter `-d` means dencryption.

``` bash
$ sops -d -i values.yaml
$ head values.yaml
image:
    repository: kong/kong-gateway
    tag: "3.1"
env:
    prefix: /kong_prefix/
    log_level: debug
    database: postgres
    proxy_url: http://www.kongtest.net:8000
    admin_gui_url: http://www.kongtest.net:8002
    admin_api_uri: http://www.kongtest.net:8001
```

After decrypt the config file, we can use is via helm to install to a Kubernetes Cluster.

## CI/CD workflow

Next, let's combian above steps and setup it up into the CI/CD workflow. The configuration file can be deployed without disclosing the plain text configuration file to the user. The decrypted configuration file also exists only in the CI/CD workflow and will be deleted when the CI/CD is finished.

The workflow is as follows.
![workflow](https://raw.githubusercontent.com/robincher/kong-mozilla-sops-demo/master/assets/workflow.png)

1. creation of Public/Private
2. encrypt the configuration file
3. Commit configuration file
4. GitHub Action
    1. install tools
    2. Getting Private key
    3. Decrypt the Configuration File
    4. Deploy Kong Gateway with helm using the configuration file.
    5. (Optional) Deploy the license key via Kong Admin API

All steps 1-3 can be done in the local environment. The point is 4-2, Private Key acquisition. If you register the Private Key in advance using the Secrets function of Github Action, you can refer to it directly in the CI/CD workflow. That means you do not have to worry about it being displayed in plain text. Also, please remember that if the Public/Private you use is not a pair, you will get an error when decrypting.

The CI/CD workflow you were writing can be found in [main.yml](https://raw.githubusercontent.com/robincher/kong-mozilla-sops-demo/master/.github/workflows/main. yaml). After committing the encrypted configuration file, you can successfully install Kong Gateway, so please give it a try.

## Summary

With CI/CD, after deploying Kong Gateway, there are still many possibilities you can do. For example, create services and routes, or restore the configuration from a backup. Likewise, if there is sensitive information in the configuration that you want to keep encrpied, you can use the same method described above to encrypt it. It's very simple so please have a try.
