# oci-arch-apex-ords
OCI APEX Application using Customer Managed ORDS

## Architecture
This Terraform IaC supports 5 different size configurations as defined in vars.tf: ALF (Always Free), S, M, L, XL with variations to the general architecture.  Review the "Setup Environment Variables" below for instructions on how to set the appropriate size (**default:** ALF).

|                              | ALF   | S     | M    | L    | XL   |
| ---------------------------- | ----- | ----- | ---- | ---- | ---- |
| **Compute Instances (CI)**   | 1     | 1     | 2    | 3    | 3    |
| **CI Horizontal Scale**      | 1     | 3     | 6    | 9    | 9    |
| **CI CPU Initial**           | 1     | 1     | 2    | 4    | 4    |
| **CI CPU Vertical Scale**    | 1     | 2     | 4    | 8    | 8    |
| **CI Memory Initial**        | 1     | 16    | 32   | 64   | 64   |
| **CI Memory Scale**          | N/A   | 32    | 64   | 192  | 192  |
| **ADB CPU Initial**          | 1     | 1     | 2    | 4    | 4    |
| **ADB CPU Scale**            | N/A   | 3     | 6    | 12   | 12   |
| **ADB Storage (TB)**         | 1     | 1     | 1    | 1    | 1    |
| **Load Balancer (Mbps Min)** | 10    | 10    | 100  | 100  | 100  |
| **Load Balancer (Mbps Max)** | 10    | 480   | 4990 | 4990 | 4990 |
| **Disaster Recovery**        | FALSE | FALSE | TRUE | TRUE | TRUE |
| **Dataguard**                | FALSE | FALSE | TRUE | TRUE | TRUE |


### XL Architecture Diagram
![OCI XL APEX/ORDS Architecture](images/XL_APEX_ORDS.png "XL APEX/ORDS Architecture")

## Assumptions
* An existing OCI tenancy; either Paid or Always Free

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
export TF_VAR_size=XL
```

It is recommended to have multiple workspaces of the VCS repository for each sized deployment due to tfstate files.

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

## Accessing APEX (Web)
After the `terraform apply` has completed, it will output the Load Balancers IPAddress such as:
```
lb_address = tolist([
  "129.159.249.211",
])
```

You can also look up the Load Balancer IP via the OCI Console.
Placing that IPAddress in a web browser will redirect you to the secure APEX port and prompt for the ADB's ADMIN password.  The ADMIN password was randomised during provisioning and is unknown.  Reset it in the OCI console to login.

# FAQ
**Q: Why front the ADB with ORDS Compute Instances**

**A:** The primary reason is to allow Friendly (i.e. https://&lt;www.YourOrganisation.com&gt;), TLS enabled URLs to APEX.  This is achived via an OCI Load Balancer which can be configured against a OCI Compute Instance running ORDS.

---
**Q: How do I make my APEX Application the default when accessing the URL**

**A:** The config_oracle.ksh script adds `<entry key="misc.defaultPage">f?p=DEFAULT:1</entry>` to the defaults.xml configuration.  The DEFAULT part of the configuration is an alias that can be set on an application.  Once an APEX Application is deployed, change its alias to DEFAULT and the end-user will be automatically redirected to it when accessing the URL:
*Shared Components* -> *Application Definition Attributes* -> Change *Application Alias*

---
**Q: How do I setup "Friendly URLs"**

**A:** 

---
**Q: How do I update the HTTPS certificate**

**A:** The infrastructure will be deployed with a self-signed certificate which will result in an warning message when visiting the APEX Application.  A valid certificate, registered against the "Friendly URL", should be applied to the Load Balancer resource before Productionisation.  Details can be found in the [SSL Certificate Management Documenation](https://docs.oracle.com/en-us/iaas/Content/Balance/Tasks/managingcertificates.htm).  Note that LetsEncrypt/CertBot can be used to manage the Load Balancer certificate as per the below Q/A.

--- 
**Q: Can I use LetsEncrypt/CertBot for Certificate Management?**

**A:** Yes.

---
**Q: How do I access the APEX Admin Page**

**A:** Where yourDomain is the IP Address of the Load Balancer, or the Domain Name after DNS updates: 
Administration Services: https://yourDomain/ords/apex_admin
Workspace Login:         https://yourDomain/ords/f?p=4550
