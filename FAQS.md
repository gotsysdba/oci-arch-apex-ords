# Frequently Asked Questions
**Q: Why front the ADB with ORDS Compute Instances**

**A:** The primary reason is to allow "Vanity" (i.e. https://&lt;www.YourOrganisation.com&gt;), TLS enabled URLs to APEX running on an Autonomous Database.  This is achived via an OCI Load Balancer which can be configured against a OCI Compute Instance running ORDS standalone.  Additionally, if you so choose, ORDS can be configured to enable Oracle REST Data Service against the Autonomous Database.

**UPDATE**: In September 2021, Oracle [announced](https://blogs.oracle.com/apex/post/introducing-vanity-urls-on-adb) suppport for Vanity URLs for OCI ADBs without the need for Customer Managed ORDS front-end.  An IaC taking advantage of this new feature: [oci-arch-apex-vanity](https://github.com/gotsysdba/oci-arch-apex-vanity).

---
**Q: Is this architecture still relevant now that Oracle supports "Vanity URLs" against the ADB**

**A:** Yes and Maybe.  For Always Free (ALF), this architecture is still the only way to get TLS enabled vanity URLs.  For Paid tenancies, this architecture allows for _transparent_ distribution of load between the Compute Instances and the ADB while adding a layer of customer managed fault tolerance.  While fault tolerance is expected, it is unclear, at this time, how much load can be catered for. 

---
**Q: Why does Always Free require the OCI CLI to be installed**

**A:** To avoid uploading the ADB Wallet to the ORDS Compute Instance, TLS has been chosen, over mTLS, to connect to the database.  However, in order to use TLS, the ADB must whitelist the IP or VCN of the ORDS server and this is where the requirement stems.  In Always Free, the ADB will not have a private end-point, meaning the ORDS compute must connect to it via the public network and so its pubic IP must be whitelisted for TLS.  Circular logic is introduced with this requirement; the ORDS compute needs the ADB provisioned to configure connectivity and the ADB needs the ORDS compute to be provisioned to whitelist its IP.  The OCI CLI is used to update the ADB's whitelist with the ORDS compute _after_ both are provisioned.

---
**Q: How do I setup "Vanity URLs"**

**A:** Once the IaC code has been deployed use the LoadBalancer's IP address and register it against your domain with your Domain Names Service provider.

---
**Q: How do I update the HTTPS certificate**

**A:** The infrastructure will be deployed with a self-signed certificate which will result in an warning message when visiting the APEX Application.  A valid certificate, registered against the "Friendly URL", should be applied to the Load Balancer resource before Productionisation.  Details can be found in the [SSL Certificate Management Documenation](https://docs.oracle.com/en-us/iaas/Content/Balance/Tasks/managingcertificates.htm).  Note that LetsEncrypt/CertBot can be used to manage the Load Balancer certificate as per the below Q/A.

--- 
**Q: Can I use LetsEncrypt/CertBot for LoadBalancer Certificate Management?**

**A:** Yes; code and instructions on how can be found in the [oci-lbaas-letsencrypt repository](https://github.com/gotsysdba/oci-lbaas-letsencrypt)

---
**Q: How do I access the APEX Admin Page**

**A:** Where yourDomain is the IP Address of the Load Balancer, or the Domain Name after DNS updates:

* Administration Services: https://yourDomain/ords/apex_admin
* Workspace Login:         https://yourDomain/ords/f?p=4550

