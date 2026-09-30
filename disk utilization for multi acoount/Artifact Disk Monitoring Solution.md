Artifact: Disk Monitoring Solution

As requested, we have created a multi‑account solution in the landing zone. The current setup includes two accounts:



Centralized Monitoring Solution



Account A



The Centralized Monitoring Solution has a central OAM sink in account 773435638052. This forms a cross‑account sink and is integrated with Account A (944599182740), which is the target account where the instance is hosted.



When scaling across multiple accounts, additional cross‑account sinks will be formed. The current Terraform code can be reused with environment parameters, enabling monitoring of multiple VMs through the centralized CloudWatch Agent.



We publish only one metric per account/region to the central monitoring account.

For example:



200 accounts × 1 metric = 200 metrics total



Instances can be monitored or data collected based on tags.



For multi‑cloud environments, we can use the Ansible code already stored in the GitHub repository.

