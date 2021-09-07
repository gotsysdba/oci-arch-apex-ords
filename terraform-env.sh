# Populate <> values and source before running terraform as per the README.md 
# Required for the OCI Provider
export TF_VAR_region="<TENANCY REGION>"
export TF_VAR_tenancy_ocid="<TENANCY OCID>"
export TF_VAR_compartment_ocid="<COMPARTMENT OCID>"
export TF_VAR_user_ocid="<USER OCID>"
export TF_VAR_fingerprint="<FINGERPRINT>"
export TF_VAR_private_key_path="<PATH TO OCI PRIVATE KEY>"

# Keys used to SSH to OCI VMs via Bastion (use cat to to populate value)
export TF_VAR_ssh_public_key=$(cat <PATH TO PUBLIC KEY>)
export TF_VAR_ssh_private_key=$(cat <PATH TO PRIVATE KEY>)

# Set the Project Abbreviation (default apexpoc)
export TF_VAR_proj_abrv="<ABBRV>"

# Set the Environment, refer to README.md for differences (default ALf)
export TF_VAR_size="<ALF|S|M|L|XL>"
