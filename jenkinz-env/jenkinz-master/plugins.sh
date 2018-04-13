#! /bin/bash

# Parse a support-core plugin -style txt file as specification for jenkins plugins to be installed
# in the reference directory, so user can define a derived Docker image with just :
#
# FROM jenkins
# COPY plugins.txt /plugins.txt
# RUN /usr/local/bin/plugins.sh /plugins.txt
#

set -e

REF=/usr/share/jenkins/ref/plugins
mkdir -p ${REF}

PLUGIN_CACHE=/tmp/plugin_cache

echo "Installing Plugins"
echo ""

while read spec || [ -n "$spec" ]; do
    plugin=("${spec%%:*}" "${spec#*:}");
    [[ ${plugin[0]} =~ ^# ]] && continue
    [[ ${plugin[0]} =~ ^\s*$ ]] && continue
    [[ -z ${plugin[1]} ]] && plugin[1]="latest"

    if [[ ${plugin[1]} =~ ^https?:// ]]
    then
        URI="${plugin[1]}"
        tmp_sub="${URI##*/}"
        plugin[1]="${tmp_sub%%.hpi}"
    else
        if [ -z "$JENKINS_UC_DOWNLOAD" ]; then
          JENKINS_UC_DOWNLOAD=$JENKINS_UC/download
        fi
        URI="${JENKINS_UC_DOWNLOAD}/plugins/${plugin[0]}/${plugin[1]}/${plugin[0]}.hpi"
    fi

    if [ -f ${PLUGIN_CACHE}/${plugin[0]}/${plugin[1]}/${plugin[0]}.jpi ];then
        echo "- Using cache : ${PLUGIN_CACHE}/${plugin[0]}/${plugin[1]}/${plugin[0]}.jpi"
        cp ${PLUGIN_CACHE}/${plugin[0]}/${plugin[1]}/${plugin[0]}.jpi $REF/${plugin[0]}.jpi
        unzip -qqo ${REF}/${plugin[0]}.jpi
    else
	echo "- Downloading ${plugin[0]}:${plugin[1]}"
        REMAINING_RETRIES=5
        CURL_EXIT_CODE=0
    	while [ $REMAINING_RETRIES -ge 0 ]; do
        	REMAINING_RETRIES=$[$REMAINING_RETRIES-1]
        	curl -sSL -C - -f "${URI}" -o $REF/${plugin[0]}.jpi && unzip -qqo $REF/${plugin[0]}.jpi && break
        	CURL_EXIT_CODE=$?
    	done

    	if [ $REMAINING_RETRIES -lt 0 ]; then
        	echo "Failed to download ${URI}" >2
        	exit $CURL_EXIT_CODE
    	fi
    fi
done  < $1
