# NoNewPermissionForAndroid

## Preparation
Before the first run, you must generate the reference snapshot file.
```
NoNewPermission::Main.new.take_snapshot
```

## Jenkins Configure
* **Build** -> **Execute shell** -> **Command**
```
#!/usr/bin/env bash
ruby no_new_permission.rb <ANDROID_SDK_PATH>/build-tools/<BUILD_TOOLS_REV>/ <ANDROID_APK_PATH>
```
