# Frequently Asked Questions
**Q: Why front the ADB with ORDS Compute Instances**

**A:** The primary reason is to allow Friendly (i.e. https://&lt;www.YourOrganisation.com&gt;), TLS enabled URLs to APEX running on an Autonomous Database.  This is achived via an OCI Load Balancer which can be configured against a OCI Compute Instance running ORDS standalone.  Additionally, if you so choose, ORDS can be configured to enable Oracle REST Data Service against the Autonomous Database. 

---
**Q: How do I make my APEX Application load when accessing the URL**

**A:** The config_oracle.ksh script adds `<entry key="misc.defaultPage">f?p=DEFAULT</entry>` to the defaults.xml configuration and creates a redirecting index.html in the documentation root.  The DEFAULT part of the configuration is an alias that can be set on the APEX application you want to load by default.  Once an APEX Application is deployed, change its alias to DEFAULT and the end-user will be automatically redirected to it when accessing the URL:
*Shared Components* -> *Application Definition Attributes* -> Change *Application Alias*

---
**Q: How do I setup "Friendly URLs"**

**A:** Once the IaC code has been deployed use the LoadBalancer's IP address and register it against your domain with your Domain Names Service provider.

---
**Q: How do I update the HTTPS certificate**

**A:** The infrastructure will be deployed with a self-signed certificate which will result in an warning message when visiting the APEX Application.  A valid certificate, registered against the "Friendly URL", should be applied to the Load Balancer resource before Productionisation.  Details can be found in the [SSL Certificate Management Documenation](https://docs.oracle.com/en-us/iaas/Content/Balance/Tasks/managingcertificates.htm).  Note that LetsEncrypt/CertBot can be used to manage the Load Balancer certificate as per the below Q/A.

--- 
**Q: Can I use LetsEncrypt/CertBot for LoadBalancer Certificate Management?**

**A:** Yes; code and instructions on how can be found in the [oci-lbaas-letsencrypt repository](https://github.com/ukjola/oci-lbaas-letsencrypt)

---
**Q: How do I access the APEX Admin Page**

**A:** Where yourDomain is the IP Address of the Load Balancer, or the Domain Name after DNS updates: 
Administration Services: https://yourDomain/ords/apex_admin
Workspace Login:         https://yourDomain/ords/f?p=4550

