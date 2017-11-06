#!/usr/bin/env bash

if [ $# -ne 5 ]; then
  echo 'Usage:'
  echo './nomad-service-deploy.sh /path/to/nomad /path/to/job.nomad my_job 30 true'
  exit 100
fi

nomad_path=$1
nomad_file=$2
job_name=$3
timeout=$4
monitor=$5

sleep=5

# start by running the job and capture the exit code
job_command="${nomad_path} run ${nomad_file}"
eval $job_command
ret_code=$?

if [ $ret_code != 0 ]; then
  printf "Error : [%d] when executing command: '${job_command}'" $ret_code
  exit $ret_code
fi

start_time=`date +%s`

end_time=$(($start_time + $timeout))
while [ `date +%s` -gt $end_time ]; do
  check_command="${nomad_path} job status ${job_name} | grep 'Status' | head -n 1 | sed 's/ //g'"
  if [ "${check_result}" == "Status=running" ]; then
    echo 'Deployment Successful'
    exit 0
  fi
  sleep $sleep
done

# Oops we timed out
echo "Timeout reached, depolyment took longer to enter status 'running' than possible expected"
exit 123
