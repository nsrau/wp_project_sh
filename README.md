# WP bash project
### Script for create or completely delete a wordpress project from mac or ubuntu

## This script must be run as root

```bash
"###################################"
"# WP bash project                 #"
"# Create or delete                #"
"###################################"

"Usage: run.sh [-help] [-create <sitename.com>] [-delete <sitename.com>] [-y <confirm delete>]"
"Options"
"  -help, --h"
"    Show this information"
"  -create, --c sitename.com"
"    Create new wordpress project sitename.com"
"  -delete, --d sitename.com"
"    Complete delete wordpress project sitename.com"
```

### example Usage
#### create new wordpress project
```
sudo ./run.sh -create sitename.com
```
#### delete wordpress project
```
sudo ./run.sh -delete sitename.com
```

### dependencies
It is necessary to have **wget** installed on the pc itself, **unzip** and obviously **apache2** so that everything works correctly.
