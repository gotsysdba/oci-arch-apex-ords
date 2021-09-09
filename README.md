# oci-arch-apex-ords
![Oracle APEX](images/APEX_Logo.png "Oracle APEX") OCI APEX Application using Customer Managed ORDS

## Architecture
This Terraform IaC supports 4 different size configurations as defined in vars.tf: ALF (Always Free), S, M, L with variations to the general architecture.  Review the "Setup Environment Variables" below for instructions on how to set the appropriate size (**default:** ALF).

|                              | ALF   | S     | M    | L    | 
| ---------------------------- | ----- | ----- | ---- | ---- |
| **Compute Instances (CI)**   | 1     | 1     | 2    | 3    | 
| **CI Horizontal Scale**      | 1     | 3     | 6    | 9    |
| **CI CPU Initial**           | 1     | 1     | 2    | 4    |
| **CI CPU Vertical Scale**    | 1     | 2     | 4    | 8    |
| **CI Memory Initial**        | 1     | 16    | 32   | 64   |
| **CI Memory Scale**          | N/A   | 32    | 64   | 192  |
| **ADB CPU Initial**          | 1     | 1     | 2    | 4    |
| **ADB CPU Scale**            | N/A   | 3     | 6    | 12   |
| **ADB Storage (TB)**         | 1     | 1     | 1    | 1    |
| **Load Balancer (Mbps Min)** | 10    | 10    | 100  | 100  |
| **Load Balancer (Mbps Max)** | 10    | 480   | 4990 | 4990 |
| **High Availabity**          | FALSE | FALSE | TRUE | TRUE |
| **Disaster Recovery**        | FALSE | FALSE | TRUE | TRUE |
| **Dataguard**                | FALSE | FALSE | TRUE | TRUE |


### L Architecture Diagram
![OCI L APEX/ORDS Architecture](images/L_APEX_ORDS.png "L APEX/ORDS Architecture")

* [Other Sizes Architecture Diagrams](ARCHITECTURE.md)
* [Architecture Details](ARCHITECTURE_DETAILS.md)

## Assumptions
* An existing OCI tenancy; either Paid or Always Free

## Load Balancer Certificates
Example self-signed certificates are created by terraform for testing purposes only and should not be used for Production.  Update the Load Balancer in the OCI console with real certificates; or utilise LetsEncrypt/CertBot as documented in the [oci-lbaas-letsencrypt repository](https://github.com/ukjola/oci-lbaas-letsencrypt)

## Installation
### **Resource Manager**
Deploy this Stack using OCI Resource Manager:

[![Deploy to Oracle Cloud][magic_button]][magic_arch_stack]

### **Terraform CLI**
#### **Setup Environment Variables**
Update the [terraform-env.sh](terraform-env.sh) file. 

You'll need to update three fields with values you can find in the [OCI console](https://console.us-phoenix-1.oraclecloud.com/):

* TF_VAR_compartment_ocid
* TF_VAR_tenancy_ocid
* TF_VAR_user_ocid

To change the default ALF (Always Free) sizing, manaully set TF_VAR_size to either S, M, or L; for example:

```
export TF_VAR_size=S
```

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
TF_VAR_fingerprint=50:d0:7d:f7:0e:05:cd:87:3b:2a:cb:50:b1:17:90:e9
TF_VAR_api_private_key_path=~/.oci/oci_api_key.pem
TF_VAR_user_ocid=ocid1.user....ewc5a
```

It is recommended to have multiple workspaces of the VCS repository for each sized deployment due to tfstate files.

#### **Install Terraform**
Instructions on installing Terraform are [here](https://www.terraform.io/intro/getting-started/install.html).  The manual, pre-compiled binary installation is, by far, the easiest and quickest way to start using Terraform.

You can test that the install was successful by running the command:
    terraform

You should see usage information returned.

#### **Build the Architecture**
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

# FAQs
[Frequently Asked Questions](FAQS.md)

[magic_button]: https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg
[magic_arch_stack]: https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/ukjola/oci-arch-apex-ords/oci-arch-apex-ords.zip