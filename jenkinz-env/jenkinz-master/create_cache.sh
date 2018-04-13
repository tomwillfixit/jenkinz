#!/bin/bash

set -e

JENKINS_UC=https://updates.jenkins-ci.org

PLUGIN_CACHE=plugin_cache

if [ ! -d ${PLUGIN_CACHE} ];then
    echo "Creating ${PLUGIN_CACHE} directory"
    mkdir -p ${PLUGIN_CACHE}
    touch ${PLUGIN_CACHE}/.gitignore
fi

echo "Creating Plugin Cache"

while read spec || [ -n "$spec" ]; do
    plugin=("${spec%%:*}" "${spec#*:}");
    [[ ${plugin[0]} =~ ^# ]] && continue
    [[ ${plugin[0]} =~ ^\s*$ ]] && continue
    [[ -z ${plugin[1]} ]] && plugin[1]="latest"

    if [[ ${plugin[1]} =~ ^https?:// ]];then
        URI="${plugin[1]}"
        tmp_sub="${URI##*/}"
        plugin[1]="${tmp_sub%%.hpi}"
    else
        if [ -z "$JENKINS_UC_DOWNLOAD" ]; then
          JENKINS_UC_DOWNLOAD=$JENKINS_UC/download
        fi
        URI="${JENKINS_UC_DOWNLOAD}/plugins/${plugin[0]}/${plugin[1]}/${plugin[0]}.hpi"
    fi

    REMAINING_RETRIES=5
    CURL_EXIT_CODE=0
    while [ $REMAINING_RETRIES -ge 0 ]; do
       	REMAINING_RETRIES=$[$REMAINING_RETRIES-1]
	if [ -f $PLUGIN_CACHE/${plugin[0]}/${plugin[1]}/${plugin[0]}.jpi ];then
	    echo "Plugin already exists in cache : ${plugin[0]}.jpi" && break
	else
	    echo "- Downloading ${plugin[0]}:${plugin[1]}"
            mkdir -p $PLUGIN_CACHE/${plugin[0]}/${plugin[1]}
       	    curl -sSL -C - -f "${URI}" -o $PLUGIN_CACHE/${plugin[0]}/${plugin[1]}/${plugin[0]}.jpi && break
       	    CURL_EXIT_CODE=$?
	fi
    done

    if [ $REMAINING_RETRIES -lt 0 ]; then
       	echo "Failed to download ${URI}" >2
       	exit $CURL_EXIT_CODE
    fi

done < $1
