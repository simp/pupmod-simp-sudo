require 'spec_helper'

describe 'sudo::include_dir' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }
        let(:title) { 'include_dir_spec' }

        context 'default parameters' do
          let(:params) do
            {
              include_dir: '/etc/sudoers.d',
            }
          end

          # The directory matches the distribution default (0750) and must
          # not recurse: recursion would force the directory mode onto
          # pre-existing unmanaged files (simp/pupmod-simp-sudo#138).
          it do
            is_expected.to create_file('/etc/sudoers.d')
              .with(
                  ensure:  'directory',
                  mode:    '0750',
                  owner:   'root',
                  group:   'root',
                  purge:   false,
                  recurse: false,
                )
            is_expected.to create_file('/etc/sudoers.d/1000_includedir__etc_sudoers_d')
              .with_content("#includedir /etc/sudoers.d\n")
          end

          it do
            is_expected.to create_file('/etc/sudoers.d/1000_includedir__etc_sudoers_d')
              .with_validate_cmd('/usr/sbin/visudo -cf %')
              .that_notifies('Exec[visudo strict configuration check]')
          end
        end

        context 'with tidy_include_dir => true' do
          let(:params) do
            {
              include_dir: '/etc/sudoers.d',
              tidy_include_dir: true,
            }
          end

          it do
            is_expected.to create_file('/etc/sudoers.d')
              .with(
                  ensure:  'directory',
                  purge:   true,
                  recurse: true,
                )
          end
        end
      end
    end
  end
end
