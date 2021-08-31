# oci-arch-apex-ords
OCI APEX Application using Customer Managed ORDS

## Architecture
This IaC supports 5 different size configurations: ALF (Always Free), S, M, L, XL with variations to the general architecture.  Review the "Setup Environment Variables" below for instructions on how to set the appropriate environment (default: ALF)

|         | Compute Instances (CI) | CI Horizontal Scale | CI CPU Initial | CI CPU Vertical Scale | CI Memory Initial | CI Memory Scale | ADB CPU Initial | ADB CPU Scale | Load Balancer (Mbps Min) | Load Balancer (Mbps Max) | Disastor Recovery | Dataguard |
| ------- | ---------------------- | ----------------------- | ------ | --------------------- | --------- | --------------- | ------- | ------------- | ------------------------ | ------------------------ | ----------------- | --------- |
| __XL__ | 3 | 9 | 4 | 8 | 64 | 192 | 4 | 12  | 100 | 4990 | TRUE  | TRUE  |
| __L__ | 3 | 9 | 4 | 8 | 64 | 192 | 4 | 12  | 100 | 4990 | TRUE  | TRUE  |
| __M__ | 3 | 9 | 4 | 8 | 64 | 192 | 4 | 12  | 100 | 4990 | TRUE  | TRUE  |
| __S__ | 1 | 3 | 1 | 2 | 16 | 48  | 1 | 3   | 10  | 4990 | FALSE | FALSE |
| __ALF__ | 1 | 1 | 1 | 1 | 16 | N/A | 1 | N/A | 10  | N/A  | FALSE | FALSE |

![OCI APEX Architecture](images/APEX_Adv.png "APEX Architecture")

## Assumptions
* Existing OCI tenancy; including Always Free
* The deployment will be performed from a Linux or MacOS system (non-Windows)

## Prerequisites
### Setup Keys

Create an SSH keypair for connecting to VM instances via the bastion by following [these instructions](https://docs.cloud.oracle.com/iaas/Content/GSG/Tasks/creatingkeys.htm).  Then create a key for OCI API access by following the instructions [here](https://docs.cloud.oracle.com/iaas/Content/API/Concepts/apisigningkey.htm).

You really just need to run the commands below in a terminal (**not** as root):

```
ssh-keygen -t rsa -N "" -b 2048 -f ~/.ssh/oci
mkdir ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
```

The output of `openssl` can be slightly different between OS's when generating the fingerprint of the public key. Run one of the following to make a correctly formatted fingerprint and to copy the public key to paste into the OCI console.

<details><summary>macOS</summary>

```
openssl rsa -pubout -outform DER -in ~/.oci/oci_api_key.pem | openssl md5 -c > ~/.oci/oci_api_key.fingerprint
cat ~/.oci/oci_api_key_public.pem | pbcopy
```
</details>

<details><summary>Linux</summary>

```
openssl rsa -pubout -outform DER -in ~/.oci/oci_api_key.pem | openssl md5 -c | awk '{print $2}' > ~/.oci/oci_api_key.fingerprint
cat ~/.oci/oci_api_key_public.pem | xclip -selection clipboard
```
</details>

Open a web browser to the console [here](https://console.us-phoenix-1.oraclecloud.com/a/identity/users).  Then select your user, click "Add Public Key" and paste it into the dialog.

### Load Balancer Certificates
Example self-signed certificates are created by terraform for testing purposes only and should not be used for Production.  Update the Load Balancer in the OCI console with real certificates.

### Setup Environment Variables
Update the [terraform-env.sh](terraform-env.sh) file. 

The script pulls values from the keys you created in the earlier steps.  You'll need to update three fields with values you can find in the [console](https://console.us-phoenix-1.oraclecloud.com/):

* TF_VAR_compartment_ocid
* TF_VAR_tenancy_ocid
* TF_VAR_user_ocid

When you've set all the variables, source the file with the command `source ./terraform-env.sh` or you could stick the contents of the file in `~/.bash_profile`:
```
source ./terraform-env.sh
```

Use the command `env | grep TF` to see the variables set by the environment file. It should look something like the following:
```
env | grep TF
TF_VAR_tenancy_ocid=ocid1.tenancy....zhi3q
TF_VAR_compartment_ocid=ocid1.compartment....e7e5q
TF_VAR_region=us-ashburn-1
TF_VAR_ssh_private_key=-----BEGIN OPENSSH PRIVATE KEY-----
TF_VAR_fingerprint=50:d0:7d:f7:0e:05:cd:87:3b:2a:cb:50:b1:17:90:e9
TF_VAR_private_key_path=~/.oci/oci_api_key.pem
TF_VAR_ssh_public_key=ssh-rsa AAAAB....kQzpF user@hostname
TF_VAR_user_ocid=ocid1.user....ewc5a
```

To change the default ALF (Always Free) sizing, set TF_VAR_size to either S, M, L, or XL; for example:

```
export TF_VAR_environment=XL
```

It is recommended to have separate clones of the VCS repository for each sized deployment due to tfstate files.

## Deploy Using the Terraform CLI
### Install Terraform
Instructions on installing Terraform are [here](https://www.terraform.io/intro/getting-started/install.html).  The manual, pre-compiled binary installation is, by far, the easiest and quickest way to start using Terraform.

You can test that the install was successful by running the command:
    terraform

You should see usage information returned.

### Build the Architecture
Once the environment has been setup.  Run the following to build the infrastructure:

```
terraform init
terraform plan
terraform apply
```

## Accessing APEX/SQLDeveloper (Web)
After the `terraform apply` has completed, it will output an IPAddress such as:
```
lb_address = tolist([
  "129.159.249.211",
])
```

Placing that IPAddress in a web browser will redirect you to the secure APEX port and prompt for the ADB's ADMIN password.  The ADMIN password was randomised during provisioning and is unknown.  Reset it in the OCI console to login.

SQLDeveloper Web is also accessible at that IPAddress: https://&lt;IPAddress&gt;/ords/sql-developer


## FAQ
**Q: Why front the ADB with ORDS Compute Instances**

**A:** Because

**Q: How do I make my APEX Application the default when accessing the URL**

**A:** The config_oracle.ksh script adds `<entry key="misc.defaultPage">f?p=DEFAULT:1</entry>` to the defaults.xml configuration.  The DEFAULT part of the configuration is an alias that can be set on an application.  Once an APEX Application is deployed, change its alias to DEFAULT and the end-user will be automatically redirected to it when accessing the URL:
*Shared Components* -> *Application Definition Attributes* -> Change *Application Alias*

**Q: How do I access the APEX Admin Page**

**A:** Administration Services: https://yourdomain/ords/apex_admin
 Workspace Login:         https://yourdomain/ords/f?p=4550