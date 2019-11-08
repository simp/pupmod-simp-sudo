# Matches the list configuration items for which  defaults can be set
# in the sudoers file.
type Sudo::DefType = Enum['base', 'cmnd', 'host', 'user', 'runas']
