#
#  Set a fact for the version of sudo.  Needed to check if mitigation
#  for CVE-2019-14287 is needed.
#
Facter.add('sudo_version') do
  setcode do
    out = Facter::Core::Execution.execute('sudo -V', on_fail: nil)
    out.to_s.lines.first&.split&.last
  end
end
