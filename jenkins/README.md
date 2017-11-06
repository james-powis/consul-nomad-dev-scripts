### Jenkins Scripts

The idea here is that these scripts facilitate in jenkins managing and accurately accessing the success
or failure of the deployment.

#### nomad-service-deploy.sh

This script is a POC for how to execute a nomad deploy as part of a jenkins pipeline. While not fully featured, it hopefully will be expanded to perform additional sanity checks including querying consul for service check status.

###### Usage:

```bash
./nomad-service-deploy.sh ${path_to_nomad} ${path_to_job} ${job_name} ${timeout} ${wait}
./nomad-service-deploy.sh /path/to/nomad /path/to/job.nomad my_job_name 30 true
```


