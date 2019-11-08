#
#  Set a fact for the version of sudo.  Needed to check if mitigation
#  for CVE-2019-14287 is needed.
#
Facter.add("sudo_version") do
  sudo_cmd = Facter::Util::Resolution.which('sudo')
  confine { sudo_cmd && File.executable?(sudo_cmd) }
  setcode do
    Facter::Core::Execution.execute("#{sudo_cmd} -V").chomp.split("\n")[0].split(/\s+/)[-1]
  end
end

