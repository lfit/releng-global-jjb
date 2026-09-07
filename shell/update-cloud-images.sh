#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# Auto-update packer image{s} when the job is started manually or a single
# image passed by upstream packer merge job:
# 1. Get a list of image{s} from the releng/builder repository
# 2. Search openstack cloud for the latest image{s} available or use the image
#    name passed down from the upstream job.
# 3. Compare the time stamps of the new image{s} with the image in use
# 4. Update the image{s} in the config files and yaml files
# 5. Push the change to Gerrit

echo "---> update-cloud-images.sh"

set -euf -o pipefail

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-activate-venv python-openstackclient

# Number of newest images per type to inspect for provenance. Every check
# costs an API call, and the image this job wants is the newest one this
# Jenkins built, which sorts to the top.
IMAGE_CANDIDATE_LIMIT="${IMAGE_CANDIDATE_LIMIT:-10}"

# Report which CI build produced an image. common-packer stamps this from the
# Jenkins BUILD_URL. Images published before that stamping return an empty
# string, as do images built outside Jenkins.
image_build_url() {
    openstack image show -f value -c properties "$1" 2>/dev/null \
        | grep -o "'build_url': '[^']*'" | cut -d"'" -f4 || true
}

mkdir -p "$WORKSPACE/archives"
echo "INFO: List of images in use on the source repository:"
grep -Er '(_system_image:|IMAGE_NAME)'                       \
    --exclude-dir="global-jjb" --exclude-dir="common-packer" \
    | grep -oP 'ZZCI\s+.*\d+-\d+\.\d+' | sort -n | uniq      \
    | tee "$WORKSPACE/archives/used_image_list.txt"

while read -r line ; do
    image_in_use="${line}"

    # get image type - ex: builder, docker, gbp etc
    image_type="${line% -*}"
    # Get the latest images available on the cloud, when $NEW_IMAGE_NAME env
    # var is unset and update all images on Jenkins to the latest.
    if [[ $NEW_IMAGE_NAME != all ]]; then
        new_image=${NEW_IMAGE_NAME}
        new_image_type="${NEW_IMAGE_NAME% -*}"
        # get the $new_image_type to check the image type is being compared
        if [[ ${new_image_type} != "${image_type}" ]]; then
            echo "INFO: Image type does not match, continue ..."
            continue
        fi
    else
        # Sort by name so the newest timestamp wins regardless of the order
        # the image API happens to return rows in.
        #
        # This used to also require Protected=False, which silently disabled
        # the whole sweep: openstack-protect-in-use-images.sh protects the
        # images this job selects from, so every candidate is Protected=True
        # and the filter matched nothing. That is why image pins went stale
        # and had to be bumped by hand.
        #
        # Name order alone cannot tell an image built by this project's packer
        # job from one published by anyone else sharing the tenant: every ZZCI
        # image carries the same ci_managed=yes metadata and the same owner.
        # Adopting a foreign image that merely sorts newer has repeatedly
        # reverted image pins that were corrected by hand. common-packer
        # stamps build_url from the Jenkins BUILD_URL, so a candidate whose
        # build_url starts with $JENKINS_URL provably came from this instance.
        #
        # Images published before that stamping carry no build_url at all.
        # While no candidate for this image type is stamped the sweep keeps
        # its previous name-only behaviour, so projects that have not rebuilt
        # yet keep updating. Once any candidate is stamped the stamp becomes
        # mandatory and a foreign image can no longer win.
        candidates=$(openstack image list --long --sort name:desc \
            -f value -c Name \
            | grep "^${image_type} - " | head -n "$IMAGE_CANDIDATE_LIMIT")     \
            || true

        new_image=""
        stamped_seen="false"
        while read -r candidate; do
            [[ -z $candidate ]] && continue
            candidate_url=$(image_build_url "$candidate")
            [[ -z $candidate_url ]] && continue
            stamped_seen="true"
            if [[ -n ${JENKINS_URL:-} && $candidate_url == "${JENKINS_URL}"* ]]
            then
                new_image="$candidate"
                break
            fi
            echo "INFO: Skipping $candidate, built elsewhere: $candidate_url"
        done <<< "$candidates"

        if [[ -z $new_image ]] && [[ $stamped_seen == "false" ]]; then
            new_image=$(printf '%s\n' "$candidates" | head -n1)
            echo "WARNING: No candidate for $image_type carries a build_url" \
                "stamp, falling back to name order. Provenance stays" \
                "unverified until this image type is rebuilt."
        fi
    fi
    if [[ -z $new_image ]]; then
        echo "INFO: No candidate image found for: $image_type"
        continue
    fi
    echo "INFO: Found image type match, compare timestamps."

    # Report which build produced the candidate so the Gerrit reviewer can
    # check its provenance before approving the bump. Images published before
    # common-packer started stamping build_url report 'unknown'.
    build_url=$(image_build_url "$new_image")
    echo "INFO: Candidate image: $new_image"
    echo "INFO: Built by: ${build_url:-unknown}"

    # strip the timestamp from the image name
    new_image_isotime=${new_image##*- }
    image_in_use_isotime=${image_in_use##*- }
    # Remove '-' & '.' from the timestamp and perform numeric compare
    if [[ ${new_image_isotime//[\-\.]/} -gt ${image_in_use_isotime//[\-\.]/} ]]; then
        # generate a patch to be submited to Gerrit
        echo "INFO: Update old image: $image_in_use with new image: $new_image"
        grep -rlE '(_system_image:|IMAGE_NAME)' \
            | xargs sed -i "s/${image_in_use}/${new_image}/"
        # When the script is triggered by upstream packer-merge job
        # update only the requested image and break the loop
        [[ $NEW_IMAGE_NAME != all ]] && break
    else
        echo "INFO: No new image to update: $new_image"
    fi
done < "$WORKSPACE/archives/used_image_list.txt"

git diff > "$WORKSPACE/archives/new-images-patchset.diff"
git add -u
git status
