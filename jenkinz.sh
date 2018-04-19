#!/bin/bash

version="0.1"

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
    echo "  -u | --usage     	 : Usage";
    echo ""
    echo "Housekeeping: "
    echo "    "
    echo "jenkinz stop  : Stops the jenkinz environment"
    echo "jenkinz clean : Removes jenkinz environment"
    echo "jenkinz total-clean : Removes jenkinz environment and data volumes used by jenkinz"
    echo ""
    kill -INT $$
}

function sanity_check
{

if [ ! -d ${repository} ];then
    echo "Repository provided does not exist : ${repository}"
    echo "Exiting"
    kill -INT $$ 
fi

if [ ! -f ${repository}/${filename} ];then
    echo "Filename provided does not exist in repository: ${repository}"
    echo "Exiting"
    kill -INT $$ 
fi

}
 
function jenkinz 
{

#set variables
stop="false"
clean="false"
totalclean="false"
usage="false"
repository=""
filename=""
number_of_builds=1

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
          -u | --usage )      local usage="true";      shift;;
          stop )              local stop="true";      shift;;
          clean )             local clean="true";      shift;;
          total-clean )       local totalclean="true";      shift;;
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

if [[ -z "${repository}" ]]; then
    echo "A valid repository must be provided"
    usage
fi

if [[ -z "${filename}" ]];then
    echo "Using default Jenkinsfile"
    filename="Jenkinsfile"
fi


echo "[] Starting jenkinz v${version}"

    sanity_check
    build-environment
    start-master
    start-slave ${repository} ${filename}

    for ((build_num=1; build_num <= ${number_of_builds}; ++build_num));
    do
        ./sync_workspace ${repository} jenkinz-workspace
        echo "Starting Build : ${repository} ${filename} ${build_num}"
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
docker exec -it jenkinz /bin/bash -c "start_jenkins thshaw/jenkinz-master:2.107.1"
docker exec -it jenkinz /bin/bash -c "get_token jenkins"
}

function start-slave()
{
repository=$1
filename=$2
TOKEN=$(docker exec -it jenkinz /bin/bash -c "cat .jenkins.auth_token")
AGENT_LABEL=$(cat ${repository}/${filename} | grep label | awk -F"'" '{ print $2 }')
docker exec -d -e TOKEN=${TOKEN} -e AGENT_LABEL=${AGENT_LABEL} jenkinz /bin/bash -c "connect ${TOKEN} ${AGENT_LABEL}"
}

function start-build()
{
repository=$1
filename=$2
build_num=$3

AGENT_LABEL=$(cat ${repository}/${filename} | grep label | awk -F"'" '{ print $2 }')
TOKEN=$(docker exec -it jenkinz /bin/bash -c "cat .jenkins.auth_token")
docker exec -d -e TOKEN=${TOKEN} -e AGENT_LABEL=${AGENT_LABEL} jenkinz /bin/bash -c "create_pipeline jenkins ${repository} ${filename}"
sleep 15
start_stats ${repository} ${build_num}
docker exec -it -e repository=${repository} jenkinz /bin/bash -c 'java -jar /opt/jenkins-cli.jar -noKeyAuth -s http://0.0.0.0:8080 build "${repository}" -s -f -v'
sleep 15
stop_stats build-stats/${repository}.${build_num}.pid
docker exec -it -e repository=${repository} jenkinz /bin/bash -c 'java -jar /opt/jenkins-cli.jar -noKeyAuth -s http://0.0.0.0:8080 console "${repository}"' > build-logs/${repository}.${build_num}.build.log

echo "Log saved to : build-logs/${repository}.${build_num}.build.log"
echo "Stats written to : build-stats/${repository}.${build_num}.stats"
process_stats build-stats/${repository}.${build_num}.stats
}

start_stats()
{
repository=$1
build_num=$2

docker stats --format "table {{.CPUPerc}}\t{{.NetIO}}\t{{.MemUsage}}\t{{.BlockIO}}" jenkinz >> build-stats/${repository}.${build_num}.stats & echo $! > build-stats/${repository}.${build_num}.pid

stats_pid=$(cat ./build-stats/${repository}.${build_num}.pid)
echo "Stats PID : ${stats_pid}"
}

stop_stats()
{
pid_file=$1

stats_pid=$(cat ${pid_file})
echo "Stopping Stats PID : ${stats_pid}"
kill ${stats_pid} &>/dev/null
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
echo "Cleaning out jenkinz-workspace"
rm -rf jenkinz-workspace/*
kill -INT $$
}

