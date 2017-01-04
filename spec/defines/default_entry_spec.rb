require 'spec_helper'

describe 'sudo::default_entry' do
 context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts){ os_facts }

        let(:title) { 'default_entry_spec'}

        context 'default parameters' do
          let(:params) { {:content => ['first', 'second']} }

          it { should compile.with_all_deps }
          it do
            should create_simpcat_fragment('sudoers+default_entry_spec.default') \
              .with_content("\nDefaults    first, second\n\n")
          end
        end

        context 'def_type = host and target specified' do
          let(:params) { {:content => ['first', 'second'], :def_type => 'host', 
            :target => 'some_host_target'} }

          it { should compile.with_all_deps }
          it do
            should create_simpcat_fragment('sudoers+default_entry_spec.default') \
              .with_content("\nDefaults@some_host_target    first, second\n\n")
          end
        end

        context 'def_type = user' do
          let(:params) { {:content => ['first', 'second'], :def_type => 'user'} }

          it { should compile.with_all_deps }
          it do
            should create_simpcat_fragment('sudoers+default_entry_spec.default') \
              .with_content("\nDefaults:    first, second\n\n")
          end
        end

        context 'def_type = runas' do
          let(:params) { {:content => ['first', 'second'], :def_type => 'runas'} }

          it { should compile.with_all_deps }
          it do
            should create_simpcat_fragment('sudoers+default_entry_spec.default') \
              .with_content("\nDefaults>    first, second\n\n")
          end
        end
      end
    end
  end
end
