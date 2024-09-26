# Scripts

**Setup the OS:**

```
wget -qO - https://raw.githubusercontent.com/alxmagro/sh/main/setup-os/1_dependencies.sh | bash
wget -qO - https://raw.githubusercontent.com/alxmagro/sh/main/setup-os/2_apps.sh | bash
wget -qO - https://raw.githubusercontent.com/alxmagro/sh/main/setup-os/3_devtools.sh | bash
wget -qO - https://raw.githubusercontent.com/alxmagro/sh/main/setup-os/4_docker.sh | bash
wget -qO - https://raw.githubusercontent.com/alxmagro/sh/main/setup-os/5_git.sh | bash
wget -qO - https://raw.githubusercontent.com/alxmagro/sh/main/setup-os/6_customs.sh | bash
```

**Wonderwall:**

Wonderwall is a bash script that sets a wallpaper every day.

```
wget -qO - https://raw.githubusercontent.com/alxmagro/sh/main/wonderwall/install.sh |
bash -s -- PATH_TO_SCRIPT PATH_TO_WALLPAPER
```
