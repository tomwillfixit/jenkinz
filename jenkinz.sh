#!/bin/bash

version="0.10"

# This script should be sourced before running any "jenkinz (command)"

## functions 

function usage
{
    echo ""
    echo "Before running jenkinz you must source the script : source ./jenkinz.sh"
    echo ""
    echo "Usage: jenkinz -r <repository name> [-f <name of Jenkinsfile> -b <number of builds>]"
    echo "   ";
    echo "  -r | --repository      : Name of the repository containing the Jenkinsfile";
    echo "  -f | --filename    	 : Defaults to Jenkinsfile";
    echo "  -b | --builds     	 : Number of Builds";
    echo "  -i | --image     	 : Official Jenkins Master Image (Default : jenkins/jenkins:2.192)";
    echo "  -c | --chaos           : Defaults to the chaos.cb file in jenkinz repository";
    echo "  -u | --usage     	 : Usage";
    echo ""
    echo "Helper functions: "
    echo "    "
    echo "jenkinz list-tags : Displays list of Image tags from the official Jenkins repository"
    echo "jenkinz stop  : Stops the jenkinz environment"
    echo "jenkinz clean : Removes jenkinz environment"
    echo "jenkinz total-clean : Removes jenkinz environment and data volumes used by jenkinz"
    echo ""
    kill -INT $$
}

function sanity_check
{

if [ ! -d ${repository} ];then
    echo "[${script_name}] ... Repository provided does not exist : ${repository}"
    echo "[${script_name}] ... Exiting"
    kill -INT $$ 
fi

if [ ! -f ${repository}/${filename} ];then
    echo "[${script_name}] ... Filename provided does not exist in repository: ${repository}"
    echo "[${script_name}] ... Exiting"
    kill -INT $$ 
fi

}

function jenkinz 
{

script_name="jenkinz"

#set variables
stop="false"
clean="false"
totalclean="false"
usage="false"
chaos="false"
repository=""
filename=""
number_of_builds=1
official_jenkins_image="jenkins/jenkins:2.192"
tags="false"

  # positional args
  args=()

  if [ "$1" = "" ];then
      usage
  fi

  # named args
  while [ "$1" != "" ]; do
      case "$1" in
          -r | --repository ) local repository="$2";             shift;;
          -f | --filename )   local filename="$2";     shift;;
          -b | --builds )     local number_of_builds="$2";      shift;;
          -i | --image )    local official_jenkins_image="$2";      shift;;
          -c | --chaos )      local chaos="true";      shift;;
          -u | --usage )      local usage="true";      shift;;
          list-tags )         local tags="true";      shift;;
          stop )              local stop="true";      shift;;
          clean )             local clean="true";      shift;;
          total-clean )       local totalclean="true";      shift;;
          shell )             local shell="true";      shift;;
      esac
      shift # move to next kv pair
  done

# housekeeping function calls; stop, clean, total-clean

if [[ "${stop}" == "true" ]];then
  stop
fi

if [[ "${clean}" == "true" ]];then
  clean
fi

if [[ "${totalclean}" == "true" ]];then
  total-clean
fi

if [[ "${shell}" == "true" ]];then
  shell 
fi

if [[ "${tags}" == "true" ]];then
  list-tags 
fi


if [[ "${chaos}" == "true" ]];then
  if [[ ! -f "./chaos.cb" ]]; then
    echo "[${script_name}] ... Unable to find default chaos.cb file. Skipping"
    chaos="false"
  else
    echo "[${script_name}] ... Using chaos.cb file : ./chaos.cb"
  fi 
fi

if [[ -z "${repository}" ]]; then
    echo "[${script_name}] ... A valid repository must be provided"
    usage
fi

if [[ -z "${filename}" ]];then
    echo "[${script_name}] ... Using default Jenkinsfile"
    filename="Jenkinsfile"
fi


echo "[] Starting jenkinz v${version}"

    sanity_check
    build-environment
    start-master
    start-agent ${repository} ${filename}

    # This only needs to be created once regardless of the number of agents and
    # uses a copy of the repository code copied to jenkinz-workspace/${repository}
    ./sync_workspace ${repository} jenkinz-workspace/${repository} 
    create-pipeline ${repository} ${filename} ${build_num}

    # Start ChaosButler here to ensure it is run just once
    if [ ${chaos} == "true" ];then
        echo "[${script_name}] ... Starting ChaosButler using profile :"
        docker cp ./chaos.cb jenkinz:/tmp/chaos.cb
        docker exec -it -e repository=${repository} jenkinz /bin/bash -c 'cat /tmp/chaos.cb'
        docker exec -d -e repository=${repository} jenkinz /bin/bash -c 'chaosbutler /tmp/chaos.cb'
    fi

    for ((build_num=1; build_num <= ${number_of_builds}; ++build_num));
    do
        ./sync_workspace ${repository} jenkinz-workspace/${repository}
        echo "[${script_name}] ... Starting Build : ${repository} ${filename} ${build_num}"
        start-build ${repository} ${filename} ${build_num}
    done
}

function build-environment()
{
docker-compose -f jenkinz.yml build
}

function start-master()
{
docker-compose -f jenkinz.yml up -d

image_tag=$(echo ${official_jenkins_image} |cut -d":" -f2)

# Pull the official image, install some plugins
#docker exec -it jenkinz /bin/bash -c "build_jenkins ${official_jenkins_image}"
# DEBUGGING
docker exec jenkinz /bin/bash -c "build_jenkins ${official_jenkins_image}"
if [ $? -ne 0 ];then
    echo "[${script_name}] ... Building Image jenkins:${image_tag} FROM ${official_jenkins_image} failed."
    kill -INT $$ 
fi

# Start container based on official image + plugins 
#docker exec -it jenkinz /bin/bash -c "start_jenkins jenkins:${image_tag}"
# DEBUGGING
docker exec jenkinz /bin/bash -c "start_jenkins jenkins:${image_tag}"
}

function start-agent()
{
repository=$1
filename=$2

TOKEN=$(docker exec jenkinz /bin/bash -c "cat /tmp/.jenkins.auth_token")
# Remove carriage return from TOKEN variable
TOKEN_STRIP=$(echo ${TOKEN} |sed 's/\r//g')

AGENT_LABELS=($(cat ${repository}/${filename} | grep label | awk -F"'" '{ print $2 }'))

for LABEL in "${AGENT_LABELS[@]}"
do
echo "[${script_name}] ... Starting Build Agent with label : ${LABEL}"
echo "DEBUG : Connecting with ${TOKEN_STRIP} ${LABEL} ${repository}"
docker exec -d jenkinz /bin/bash -c "connect ${TOKEN_STRIP} ${LABEL} ${repository}"
done
}

create-pipeline()
{

repository=$1
filename=$2
build_num=$3

#docker exec -it jenkinz /bin/bash -c "create_pipeline jenkins ${repository} ${filename}"
# DEBUGGING
docker exec jenkinz /bin/bash -c "create_pipeline jenkins ${repository} ${filename}"

}

function start-build()
{
repository=$1
filename=$2
build_num=$3

start_stats ${repository} ${build_num}

start=$SECONDS

#docker exec -it -e repository=${repository} jenkinz /bin/bash -c 'java -jar /opt/jenkins-cli.jar -noKeyAuth -s http://0.0.0.0:8080 build "${repository}"'
#docker exec -it -e repository=${repository} jenkinz /bin/bash -c 'watch-build "${repository}"'

docker exec -e repository=${repository} jenkinz /bin/bash -c 'java -jar /opt/jenkins-cli.jar -noKeyAuth -s http://0.0.0.0:8080 build "${repository}"'
docker exec -e repository=${repository} jenkinz /bin/bash -c 'watch-build "${repository}"'

end=$SECONDS

stop_stats build-stats/${repository}.${build_num}.pid

echo "Generate Post Build Report"
echo -e "\nJenkins Version :\n" > build-logs/${repository}.${build_num}.build.log
docker exec -e repository=${repository} jenkinz /bin/bash -c 'java -jar /opt/jenkins-cli.jar -noKeyAuth -s http://0.0.0.0:8080 version' >> build-logs/${repository}.${build_num}.build.log
echo -e "\nPlugin Versions :\n" >> build-logs/${repository}.${build_num}.build.log
docker exec -e repository=${repository} jenkinz /bin/bash -c 'java -jar /opt/jenkins-cli.jar -noKeyAuth -s http://0.0.0.0:8080 list-plugins' >> build-logs/${repository}.${build_num}.build.log
echo -e "\nBuild Log :\n" >> build-logs/${repository}.${build_num}.build.log
docker exec -e repository=${repository} jenkinz /bin/bash -c 'java -jar /opt/jenkins-cli.jar -noKeyAuth -s http://0.0.0.0:8080 console "${repository}"' >> build-logs/${repository}.${build_num}.build.log

echo "[${script_name}] ... Log saved to : build-logs/${repository}.${build_num}.build.log"

status=$(cat build-logs/${repository}.${build_num}.build.log |tail -1)

if [[ ${status} = *"Finished"* ]]; then 
    echo "[${script_name}] ... Build Result : ${status}" 
else 
    echo "[${script_name}] ... Unable to get "Finished" status from build log"
    status="Unable to determine build outcome"
fi

echo "[${script_name}] ... Stats written to : build-stats/${repository}.${build_num}.stats"
process_stats build-stats/${repository}.${build_num}.stats

duration=$(( end - start ))
echo "Build #${build_num}  | ${repository} took ${duration} seconds. ${status}" |tee -a results.${image_tag}.log

}

start_stats()
{
repository=$1
build_num=$2

docker stats --format "table {{.CPUPerc}}\t{{.NetIO}}\t{{.MemUsage}}\t{{.BlockIO}}" jenkinz >> build-stats/${repository}.${build_num}.stats & echo $! > build-stats/${repository}.${build_num}.pid

stats_pid=$(cat ./build-stats/${repository}.${build_num}.pid)
echo "Stats PID : ${stats_pid}"
}

function killsub() 
{

    kill -9 ${1} 2>/dev/null
    wait ${1} 2>/dev/null

}

stop_stats()
{
pid_file=$1

stats_pid=$(cat ${pid_file})
echo "[${script_name}] ... Stopping Stats PID : ${stats_pid}"
#killsub ${stats_pid}
rm ${pid_file}

}

process_stats()
{

stats_file=$1

peak_cpu_percentage=$(cat ${stats_file} |grep / |grep -v CPU |awk '{print $1}' | sort -nr | head -1)
peak_network_input=$(cat ${stats_file} |grep / |grep -v CPU |awk '{print $2}' | sort -nr | head -1)
peak_network_output=$(cat ${stats_file} |grep / |grep -v CPU |awk '{print $4}' | sort -nr | head -1)
peak_memory_usage=$(cat ${stats_file} |grep / |grep -v CPU |awk '{print $5}' | sort -nr | head -1)
peak_block_device_input=$(cat ${stats_file} |grep / |grep -v CPU |awk '{print $8}' | sort -nr | head -1)
peak_block_device_output=$(cat ${stats_file} |grep / |grep -v CPU |awk '{print $10}' | sort -nr | head -1)

rm ${stats_file}

echo "=== Build Resource Usage ========================================"
echo "The following stats are gathered using docker stats."
echo "These are the peak values for each resource used by the pipeline." 
echo "================================================================="
echo "General Usage :"
echo "--> CPU    : ${peak_cpu_percentage}"
echo "--> Memory : ${peak_memory_usage}"
echo "----------------------------"
echo "Network Usage :"
echo "--> Input  : ${peak_network_input}"
echo "--> Output : ${peak_network_output}"
echo "----------------------------"
echo "Block Device Usage :"
echo "--> Input  : ${peak_block_device_input}"
echo "--> Output : ${peak_block_device_output}"
echo "----------------------------"

echo "CPU    : ${peak_cpu_percentage}" >> ${stats_file}
echo "Memory : ${peak_memory_usage}" >> ${stats_file}
echo "Network Input  : ${peak_network_input}" >> ${stats_file}
echo "Network Output : ${peak_network_output}" >> ${stats_file}
echo "Block Input  : ${peak_block_device_input}" >> ${stats_file}
echo "Block Output : ${peak_block_device_output}" >> ${stats_file}

}

function stop()
{
docker-compose -f jenkinz.yml stop 
kill -INT $$
}

function clean()
{
docker-compose -f jenkinz.yml down
echo "Cleaning out jenkinz-workspace"
rm -rf jenkinz-workspace/*
kill -INT $$
}

function total-clean()
{
docker-compose -f jenkinz.yml down -v
echo "[${script_name}] ... Cleaning out jenkinz-workspace"
rm -rf jenkinz-workspace/*
kill -INT $$
}

function shell()
{

docker exec -it jenkinz /bin/bash

}

function list-tags
{

url="https://registry.hub.docker.com/v2/repositories/jenkinsci/jenkins/tags?page_size=1024"

IFS=$'\n' read -r -d '' -a tag_array \
  < <(set -o pipefail; curl -L -s --fail -k "$url" | jq -r '."results"[]["name"]' |grep alpine && printf '\0')

if [ -n "${tag_array}" ]; then
    printf 'jenkinsci/jenkins:%s\n' "${tag_array[@]}"
else
    echo "[${script_name}] ... Unable to get a list of tags. This may be due to curl failing or failure to extract the tags from the Dockerfile."
    exit 3
fi

kill -INT $$
}

