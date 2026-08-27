# Ensures `/etc/sudoers` actually reads this module's drop-in files:
# appends an `#includedir` directive for `sudo::content_dir` unless an
# equivalent directive is already present. Included by this module's
# defined types so that a bare `include sudo` never touches `/etc/sudoers`.
#
# @api private
class sudo::includedir {
  assert_private()

  include 'sudo'

  if $sudo::manage_includedir {
    # The match covers both directive spellings (`#includedir` and, on
    # newer sudo, `@includedir`), optional quoting, and trailing slashes on
    # the existing line — a missed match would append a second directive
    # for the same directory, and a doubled include is a parse error as
    # soon as any alias is defined. With `replace => false` an existing
    # directive is left exactly as-is and the line is only appended when
    # none is present.
    file_line { 'sudo content_dir includedir':
      path     => '/etc/sudoers',
      line     => "#includedir ${sudo::normalized_content_dir}",
      match    => sprintf('^[@#]includedir[ \t]+"?%s/*"?[ \t]*$', regexpescape($sudo::normalized_content_dir)),
      replace  => false,
      multiple => true,
      require  => Package['sudo'],
    }

    if $sudo::strict_config_check {
      File_line['sudo content_dir includedir'] ~> Exec['visudo strict configuration check']
    }
  } else {
    warning("sudo: manage_includedir is disabled -- entries written to ${sudo::normalized_content_dir} will be ignored by sudo unless /etc/sudoers contains an includedir directive for it")
  }
}
