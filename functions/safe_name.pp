# Sanitizes a resource title into a sudoers drop-in file name component.
#
# sudo ignores include-dir files whose names contain a `.`, so anything
# outside `[0-9A-Za-z_-]` is replaced with `_`. Plain substitution is not
# injective (`admin.users` and `admin_users` would collide into the same
# file, turning distinct resources into a duplicate-declaration compile
# error), so whenever sanitization changes the title, a short digest of the
# original title is appended to keep the result unique per title.
#
# @param name The resource title to sanitize
# @return [String] A filename-safe, injective transformation of the title
function sudo::safe_name(String[1] $name) >> String {
  $_sane = regsubst($name, '[^0-9A-Za-z_-]', '_', 'G')

  if $_sane == $name {
    $_sane
  } else {
    "${_sane}_${sha256($name)[0,8]}"
  }
}
