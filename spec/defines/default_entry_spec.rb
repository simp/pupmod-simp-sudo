require 'spec_helper'

describe 'sudo::default_entry' do
 context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts){ os_facts }

        let(:title) { 'default_entry_spec'}

        let(:params) { {:content => ['first', 'second']} }

        it { should compile.with_all_deps }

        it do
          should create_simpcat_fragment('sudoers+default_entry_spec.default') \
            .with_content(/first.*second/)
        end
      end
    end
  end
end
