#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> maven-fetch-metadata.sh"
# Fetches a project's maven-metadata.xml files from a Maven repository.
#
# Seeds $WORKSPACE/m2repo with the metadata Maven needs in order to continue
# an artifact's version history rather than restarting it. Without this, builds
# that deploy to a fresh -DaltDeploymentRepository restart snapshot
# buildNumbers at 1 and publish an incomplete <versions> list.
#
# Coordinates are read from the reactor poms and each maven-metadata.xml is
# requested directly, so this does not depend on remote repository browsing
# (Nexus "browseable") being enabled.

# Check for "-f" maven param, indicating a change in pom location.
pom_path="pom.xml"
file_path=$(echo "$MAVEN_PARAMS" | grep -Eo "\-f \S+" | awk '{ print $2 }')
if [ -n "$file_path" ]; then
    if [ -d "$file_path" ]; then
        pom_path="$file_path/pom.xml"
    else
        pom_path="$file_path"
    fi
fi

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

repo_url="$NEXUS_URL/content/repositories/$NEXUS_REPO"
m2repo="$WORKSPACE/m2repo"
reactor_root=$(dirname "$pom_path")

# Print "groupId:artifactId:version" for a pom, inheriting groupId and version
# from <parent> when the module does not declare them itself. Takes the element
# prefix and any additional xmlstarlet arguments so the same template can be
# applied with and without the Maven POM namespace.
read_coords() {
    local pom="$1"
    local p="$2"
    shift 2
    xmlstarlet sel "$@" -t \
        --if "/${p}project/${p}groupId" \
            -v "/${p}project/${p}groupId" \
        --elif "/${p}project/${p}parent/${p}groupId" \
            -v "/${p}project/${p}parent/${p}groupId" \
        --else -o "" -b \
        -o ":" \
        -v "/${p}project/${p}artifactId" \
        -o ":" \
        --if "/${p}project/${p}version" \
            -v "/${p}project/${p}version" \
        --elif "/${p}project/${p}parent/${p}version" \
            -v "/${p}project/${p}parent/${p}version" \
        --else -o "" -b \
        "$pom" 2>/dev/null
}

# Most poms declare the Maven POM namespace, but it is optional. Try the
# namespaced form first and fall back to the bare form.
coords_for() {
    local pom="$1"
    local coords

    coords=$(read_coords "$pom" "x:" \
        -N "x=http://maven.apache.org/POM/4.0.0") || coords=""
    if [ -z "${coords//:/}" ]; then
        coords=$(read_coords "$pom" "") || coords=""
    fi

    printf '%s' "$coords"
}

# Retrieve a single maven-metadata.xml. A missing file is not an error: the
# artifact may never have been published before.
fetch_metadata() {
    local url="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"
    if wget -q --timeout=30 --tries=2 -O "$dest" "$url"; then
        return 0
    fi

    # wget creates the output file before it knows the response code.
    rm -f "$dest"
    return 1
}

mkdir -p "$m2repo"

modules=0
fetched=0
declare -A seen_artifacts=()

while IFS= read -r pom; do
    coords=$(coords_for "$pom")
    group="${coords%%:*}"
    remainder="${coords#*:}"
    artifact="${remainder%%:*}"
    version="${remainder##*:}"

    if [ -z "$group" ] || [ -z "$artifact" ]; then
        echo "WARN: Unable to read Maven coordinates from $pom, skipping."
        continue
    fi
    modules=$((modules + 1))

    group_path="${group//.//}"

    # Artifact level metadata carries the <versions> list. A groupId/artifactId
    # pair can appear in several poms, so only fetch it once.
    if [ -z "${seen_artifacts["$group_path/$artifact"]:-}" ]; then
        seen_artifacts["$group_path/$artifact"]=1
        if fetch_metadata \
            "$repo_url/$group_path/$artifact/maven-metadata.xml" \
            "$m2repo/$group_path/$artifact/maven-metadata.xml"; then
            fetched=$((fetched + 1))
        fi
    fi

    # Version level metadata carries the snapshot buildNumber and timestamp.
    # Versions built from an unresolved property cannot be mapped to a path.
    if [ -z "$version" ] || [ "${version#*\$}" != "$version" ]; then
        continue
    fi

    if fetch_metadata \
        "$repo_url/$group_path/$artifact/$version/maven-metadata.xml" \
        "$m2repo/$group_path/$artifact/$version/maven-metadata.xml"; then
        fetched=$((fetched + 1))
    fi
done < <(find "$reactor_root" -name pom.xml -not -path '*/target/*' | sort)

if [ "$modules" -eq 0 ]; then
    echo "WARN: No Maven coordinates found below $reactor_root."
    echo "WARN: Nothing to seed, snapshot version history may restart."
elif [ "$fetched" -eq 0 ]; then
    echo "WARN: Fetched no maven-metadata.xml for $modules module(s) from"
    echo "WARN: $repo_url"
    echo "WARN: This is expected for a project that has never published."
    echo "WARN: Otherwise the repository is unreachable and this build will"
    echo "WARN: restart snapshot buildNumbers at 1 and publish an incomplete"
    echo "WARN: <versions> list."
else
    echo "INFO: Seeded $fetched maven-metadata.xml file(s) for" \
        "$modules module(s)."
fi

# Backup metadata - Used later to find metadata files that have not been
# modified so that they are not re-uploaded by maven-deploy.sh.
mkdir -p "$WORKSPACE/m2repo-backup"
if [ -n "$(ls -A "$m2repo")" ]; then
    cp -a "$m2repo/." "$WORKSPACE/m2repo-backup/"
fi
