require 'spec_helper'

# Validates the shipped `simp:defaults` compliance_engine profile. Enabling
# `compliance_engine::enforcement: [simp:defaults]` must restore the
# pre-refactor module defaults, while an explicit site-Hiera value must still
# win over the profile (the profile sits at *middle* Hiera priority).
describe 'sudo' do
  # Wire in the compliance_engine `lookup_key` backend, which the module's own
  # hiera.yaml does not provide.
  let(:hiera_config) do
    File.expand_path('../fixtures/hieradata/hiera_compliance_engine.yaml', __dir__)
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        context 'with simp:defaults enforced' do
          let(:facts) { os_facts.merge(custom_hiera: 'simp_defaults_enforced') }

          it { is_expected.to compile.with_all_deps }

          # package_ensure is the one default the refactor moved off of
          # simp_options; the profile restores it to its pre-refactor value.
          it { is_expected.to contain_package('sudo').with_ensure('installed') }
        end

        context 'with simp:defaults enforced and an explicit site override' do
          let(:facts) { os_facts.merge(custom_hiera: 'simp_defaults_with_override') }

          it { is_expected.to compile.with_all_deps }

          # The override (sudo::package_ensure: latest) must beat the profile,
          # proving the profile sits below site Hiera, not above it.
          it { is_expected.to contain_package('sudo').with_ensure('latest') }
        end
      end
    end
  end
end
