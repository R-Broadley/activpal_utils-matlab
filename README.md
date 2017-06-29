# activpal-utils-matlab
This repository contains a matlab toolbox (activpal_utils) for opening data files from activPAL&trade; devices.


## Installation
A full list of releases can be found [here](https://github.com/R-Broadley/activpal_utils-matlab/releases).

#### Install as Matlab Toolbox
This is the recommended method to install activpal_utils for Matlab.  
1. Download the latest version of the Matlab toolbox installation file (.mltbx) from [here](https://github.com/R-Broadley/activpal_utils-matlab/releases).
2. Open the .mltbx file using Matlab.
3. When prompted select Install.

#### Add activpal_utils as a module in another project
Before using this toolbox in another project check the licenses are compatible.

##### Git Subtrees Method:
Navigate to the main projets home directory and run the following git commands:  
```shell
git remote add -f activpal_utils-matlab https://github.com/R-Broadley/activpal_utils-matlab.git  
git subtree add --prefix +activpal_utils activpal_utils-matlab v1.0 --squash
```

To update run:  
```shell
git subtree pull --prefix +activpal_utils activpal_utils-matlab v# --squash
```


## Documentation
  The full [documentation](https://github.com/R-Broadley/activpal_utils-matlab/wiki/Documentation)
  is available [here](https://github.com/R-Broadley/activpal_utils-matlab/wiki/Documentation).


## Disclaimer
This toolbox is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 2, as published by the Free Software Foundation. This toolbox is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License version 2 for more details. A copy of the General Public License version 2 should be included with this toolbox. If not, see https://www.gnu.org/licenses/gpl-2.0.html.
