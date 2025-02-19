#!/bin/sh

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../jenkins/common.sh
. ${SCRIPT_LOCATION}/common.sh

PLATFORMS="${SCRIPT_LOCATION}/cloud_testing/platforms.json"
EC2_CONFIG="/etc/cvmfs-testing/ec2_config.sh"

# sanity checks
[ ! -z $CVMFS_PLATFORM ]        || die "CVMFS_PLATFORM missing"
[ ! -z $CVMFS_PLATFORM_CONFIG ] || die "CVMFS_PLATFORM_CONFIG missing"
[ ! -z $CVMFS_TESTEE_URL ]      || die "CVMFS_TESTEE_URL missing"
which jq > /dev/null 2>&1       || die "jq utility missing"

vm_desc="$(get_platform_description $CVMFS_PLATFORM $CVMFS_PLATFORM_CONFIG)"
[ ! -z "$vm_desc" ] || die "test platform not specified in $PLATFORMS"

# sanity checks for the platform description
has_platform_parameter 'label' "$vm_desc" || die "VM parameter .label missing"
has_platform_parameter 'setup' "$vm_desc" || die "VM parameter .setup missing"
has_platform_parameter 'test'  "$vm_desc" || die "VM parameter .test missing"
has_platform_parameter 'ami'   "$vm_desc" || die "VM parameter .ami missing"
has_platform_parameter 'user'  "$vm_desc" || die "VM parameter .user missing"

suites=
if [ "x${CVMFS_QUICK_TESTS}" = "xtrue" ]; then
  suites="$suites quick"
fi
if [ "x${CVMFS_DUCC_TESTS}" = "xtrue" ]; then
  suites="$suites ducc"
fi
if [ "x$suites" != "x" ]; then
  suites="-s $suites"
fi
geoip_key=
if [ "x$CVMFS_TEST_GEO_LICENSE_KEY" != x ]; then
  geoip_key="-G $CVMFS_TEST_GEO_LICENSE_KEY"
fi
destroy_failed=
if [ "x${CVMFS_DESTROY_FAILED_VMS}" = "xtrue" ]; then
  destroy_failed='-F'
fi


echo "Running cloud tests for $CVMFS_PLATFORM / $CVMFS_PLATFORM_CONFIG ..."
${SCRIPT_LOCATION}/cloud_testing/run.sh                    \
        -u $CVMFS_TESTEE_URL                               \
        -p  $(get_platform_parameter 'label'   "$vm_desc") \
        -b  $(get_platform_parameter 'setup'   "$vm_desc") \
        -r  $(get_platform_parameter 'test'    "$vm_desc") \
        -e $EC2_CONFIG                                     \
        -a  $(get_platform_parameter 'ami'     "$vm_desc") \
        -m  $(get_platform_parameter 'user'    "$vm_desc") \
        -c "$(get_platform_parameter 'context' "$vm_desc")"\
        -l "$CVMFS_CLIENT_TESTEE_URL"                      \
        $suites $geoip_key $destroy_failed

