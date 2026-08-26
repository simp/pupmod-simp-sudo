require 'spec_helper'
require 'digest'

describe 'sudo::include_dir' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }
        let(:title) { 'include_dir_spec' }

        # The content directory itself: a drop-in inside /etc/sudoers.d that
        # re-includes /etc/sudoers.d makes sudo fail with 'too many levels
        # of includes', so no drop-in may be written -- the directive for
        # the content directory is ensured by sudo::includedir instead.
        context 'with the content directory (default parameters)' do
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
          end

          it 'declares no self-referencing drop-in' do
            drop_ins = catalogue.resources.select do |r|
              r.type == 'File' && r[:path].to_s.start_with?('/etc/sudoers.d/')
            end
            expect(drop_ins).to be_empty
          end

          it { is_expected.to contain_file_line('sudo content_dir includedir') }
        end

        context 'with a separate include directory' do
          let(:params) do
            {
              include_dir: '/etc/simp_sudoers.d',
            }
          end
          let(:expected_file) do
            digest = Digest::SHA256.hexdigest('/etc/simp_sudoers.d')[0, 8]
            "/etc/sudoers.d/1000_includedir__etc_simp_sudoers_d_#{digest}"
          end

          it { is_expected.to create_file('/etc/simp_sudoers.d').with_ensure('directory') }

          it do
            is_expected.to create_file(expected_file)
              .with_content("#includedir /etc/simp_sudoers.d\n")
              .with_validate_cmd('/usr/sbin/visudo -cf %')
              .that_notifies('Exec[visudo strict configuration check]')
          end

          # The bootstrap directive comes via sudo::includedir, but no
          # legacy cleanup: the 6.x-written includedir line in /etc/sudoers
          # may be the directive keeping the drop-ins active.
          it 'declares no legacy cleanup file_lines' do
            cleanup = catalogue.resources.select do |r|
              r.type == 'File_line' && r.title.start_with?('sudo legacy cleanup')
            end
            expect(cleanup).to be_empty
          end

          context 'with ensure => absent' do
            let(:params) { super().merge(ensure: 'absent') }

            it { is_expected.to create_file(expected_file).with_ensure('absent') }
          end
        end

        context 'with a trailing slash on the content directory alias' do
          let(:params) do
            {
              include_dir: '/etc/sudoers.d/',
            }
          end

          it 'still declares no self-referencing drop-in' do
            drop_ins = catalogue.resources.select do |r|
              r.type == 'File' && r[:path].to_s.start_with?('/etc/sudoers.d/')
            end
            expect(drop_ins).to be_empty
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
