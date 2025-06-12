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

          it do
            is_expected.to create_file('/etc/sudoers.d')
              .with(
                  ensure:  'directory',
                  mode:    '0640',
                  owner:   'root',
                  group:   'root',
                  recurse: true,
                )
            is_expected.to create_concat__fragment('sudo_include_dir_/etc/sudoers.d')
              .with_content("#includedir /etc/sudoers.d\n")
          end
        end
      end
    end
  end
end
