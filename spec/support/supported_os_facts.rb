# frozen_string_literal: true

# simp-rspec-puppet-facts returns only the factsets it ships, which cover EL
# alone, so `on_supported_os` silently skips the Ubuntu releases listed in
# metadata.json. This adds the FacterDB factsets for every supported release
# it skips.
def supported_os_facts
  simp_facts = on_supported_os
  missing = RspecPuppetFacts.meta_supported_os.filter_map do |os|
    releases = os.fetch('operatingsystemrelease', []).reject do |rel|
      simp_facts.key?("#{os['operatingsystem'].downcase}-#{rel}-x86_64")
    end
    os.merge('operatingsystemrelease' => releases) unless releases.empty?
  end
  return simp_facts if missing.empty?

  simp_facts.merge(Simp::RspecPuppetFacts::Shim.on_supported_os(supported_os: missing))
end
