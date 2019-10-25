import subprocess
import sys

from packaging.version import Version
from packaging.specifiers import SpecifierSet

VERSION_RANGE_OPERATORS = ('==', '!=', '<', '<=', '>', '>=', '~=', '===')


def to_specifer_set(raw_version):
    if any(raw_version.startswith(op) for op in VERSION_RANGE_OPERATORS):
        return SpecifierSet(raw_version)
    return SpecifierSet('==%s' % raw_version)


def main():
    expected_set = to_specifer_set(sys.argv[1])
    raw_pip_version = subprocess.check_output(["pip", "--version"]).decode()
    actual_version = Version(raw_pip_version.split(' ')[1])
    if actual_version not in expected_set:
        print("FAIL: version '%s' not in set '%s'"
              % (actual_version, expected_set))
        return 1
    print("PASS: version '%s' is in set '%s'" % (actual_version, expected_set))
    return 0


if __name__ == '__main__':
    sys.exit(main())
