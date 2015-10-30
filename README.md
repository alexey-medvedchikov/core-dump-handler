# Linux core dump handler

This script handles processes core dumps and stores it in specified directory.
Also it support rotation.

Example usage:

```shell
sysctl -w kernel.core_pattern='|/bin/core-dump-handler.sh -e=%e -p=%p -s=%s -t=%t -d=/var/log/core -r=10'
```
