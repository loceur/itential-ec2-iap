
# This is a terraform plan that utilizes Itential's Deployer to build an IAP setup in EC2


This one's pretty straight forward.

This will build a 3 system t2.large and autoprovision one node as IAP/IAG, one node as redis and one as mongodb.

The vars are currently setup specifically for Itential's PM team, so if you're not us, then you'll need to change the S3 bucket and the ssh key name.

We use the latest deployer ansible galaxy collection to deploy, so there is the potential for breaking down the road if deployer makes any breaking changes.
https://galaxy.ansible.com/ui/repo/published/itential/deployer/

To run:

```
terraform apply
```


To delete:
```
terraform destroy
```
