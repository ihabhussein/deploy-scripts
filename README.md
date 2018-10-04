# Deployment Scripts

## Access Control

To allow access control, change `PermitUserEnvironment` in the `sshd` config
file (`/etc/ssh/sshd_config`) to `yes`:

    PermitUserEnvironment yes

then edit the `pre-receive` git hook to check for the `GIT__USER` value and
either exit with zero value to allow or non zero value disallow the push.
