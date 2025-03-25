# DataStage Gather Stacks utility

This compressed file contains gdb and a set of scripts that can automatically gather stack traces from running DataStage jobs in CP4D or on DataStage Anywhere containers.

Download and decompress the file to a local temporary directory on a machine that has access to px-runtime pods or containers of the px-runtime instance.
Example:
/tmp/test> tar xvfz getstacks.tar.gz 
gdb-8.2.1-x86_64.tar.gz
getstacksre.sh
getstackscpd.sh

For CP4D run the getstackscpd.sh script. The script takes 1 optional argument which is the px-runtime instance name. If not given ds-px-default is used.
Examples:
./getstackscpd.sh
./getstackscpd.sh inst1-small

For DataStage Anywhere run the getstacksre.sh script.
Usage: getstacksre.sh [OPTIONS]
Options:
  -p, --podman   Use podman command instead of docker
  -r, --repeat   Number of times to dump stacks (default: 1)
  -d, --delay    Delay between dumping stacks in seconds (default: 60)

