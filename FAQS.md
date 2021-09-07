# Frequently Asked Questions
**Q: Why front the ADB with ORDS Compute Instances**

**A:** The primary reason is to allow Friendly (i.e. https://&lt;www.YourOrganisation.com&gt;), TLS enabled URLs to APEX.  This is achived via an OCI Load Balancer which can be configured against a OCI Compute Instance running ORDS.

---
**Q: How do I make my APEX Application the default when accessing the URL**

**A:** The config_oracle.ksh script adds `<entry key="misc.defaultPage">f?p=DEFAULT</entry>` to the defaults.xml configuration.  The DEFAULT part of the configuration is an alias that can be set on an application.  Once an APEX Application is deployed, change its alias to DEFAULT and the end-user will be automatically redirected to it when accessing the URL:
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

