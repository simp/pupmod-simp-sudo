require 'spec_helper'

describe 'sudo::default_entry' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        let(:title) { 'default_entry_spec' }

        context 'default parameters' do
          let(:params) { { content: ['first', 'second'] } }

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to create_concat__fragment("sudo_default_entry_#{title}")
              .with_content("Defaults    first, second\n")
          end
        end

        context 'def_type = host and target specified' do
          let(:params) do
            { content: ['first', 'second'], def_type: 'host',
             target: 'some_host_target' }
          end

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to create_concat__fragment("sudo_default_entry_#{title}")
              .with_content("Defaults@some_host_target    first, second\n")
          end
        end

        context 'def_type = cmnd and target specified' do
          let(:params) do
            { content: ['first', 'second'], def_type: 'cmnd',
               target: 'some_cmnd_target' }
          end

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to create_concat__fragment("sudo_default_entry_#{title}")
              .with_content("Defaults!some_cmnd_target    first, second\n")
          end
        end

        context 'def_type = user' do
          let(:params) { { content: ['first', 'second'], def_type: 'user' } }

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to create_concat__fragment("sudo_default_entry_#{title}")
              .with_content("Defaults:    first, second\n")
          end
        end

        context 'def_type = runas' do
          let(:params) { { content: ['first', 'second'], def_type: 'runas' } }

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to create_concat__fragment("sudo_default_entry_#{title}")
              .with_content("Defaults>    first, second\n")
          end
        end

        context 'def_type = cmnd' do
          let(:params) { { content: ['first', 'second'], def_type: 'cmnd' } }

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to create_concat__fragment("sudo_default_entry_#{title}")
              .with_content("Defaults!    first, second\n")
          end
        end
        # Test cve 2019-14287 mitigation
        context 'test cve mitigation ' do
          let(:params) { { content: ['%ALL', '!%wheel'], def_type: 'runas' } }

          context 'sudo version < 1.8.28' do
            let(:facts) { os_facts.merge({ sudo_version: '1.8.0' }) }

            it do
              is_expected.to create_concat__fragment("sudo_default_entry_#{title}")
                .with_content("Defaults>    %ALL, !%wheel, !%#-1\n")
            end
          end
          context 'sudo version >= 1.8.28' do
            let(:facts) { os_facts.merge({ sudo_version: '1.8.30' }) }

            it do
              is_expected.to create_concat__fragment("sudo_default_entry_#{title}")
                .with_content("Defaults>    %ALL, !%wheel\n")
            end
          end
        end
      end
    end
  end
end
