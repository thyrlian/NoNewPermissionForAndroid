# NoNewPermissionForAndroid
Permission matters!  That's what users care about the most.  They hate every permission from the bottom of heart, especially the **newly added permission(s)**.  So it's better to check if you have added any new permission to your Android app by any means (e.g. the external library could bring some new permissions).

This script could help warn developers of any permission change by setting up a CI job.

## Precondition
* Ruby
* rake gem (can install by running `gem install rake`)

## Available tasks
```
$ rake -D

rake examine[android_build_tools_path,apk_file]
    Examine the apk and the snapshot to compare the permission change

rake take_snapshot[android_build_tools_path,apk_file]
    Generate the reference snapshot file, before the first run
```

## Jenkins Configure
* **Build** -> **Execute shell** -> **Command**
```
#!/usr/bin/env bash
cd <DIRECTORY_OF_THIS_SCRIPT>
rake examine[<ANDROID_SDK_PATH>/build-tools/<BUILD_TOOLS_REV>,<ANDROID_APK_PATH>]
```

## Note
* Before running the regular CI job, you must generate a snapshot file first:
```
rake take_snapshot[<ANDROID_SDK_PATH>/build-tools/<BUILD_TOOLS_REV>,<ANDROID_APK_PATH>]
```
* If you use zsh, you may encounter `no matches found`, then please try to add `\` before bracket, like below:
```
rake examine\[<ANDROID_SDK_PATH>/build-tools/<BUILD_TOOLS_REV>,<ANDROID_APK_PATH>\]
```
