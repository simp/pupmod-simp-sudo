require 'spec_helper'

describe 'sudo::alias' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts){ os_facts }

        let(:title) { :user_alias }

        let(:params) {{
          :content => ['millert', 'mikef'],
          :alias_type => 'user',
          'comment' => 'generic comment',
          'order' => '11'
        }}

        it { should compile.with_all_deps }

        it {
          should contain_simpcat_fragment('sudoers+user_user_alias_11.alias').with_content(
            /.*generic comment(\s*|.*)User_Alias(\s*|.*)USER_ALIAS(\s*|.*)millert, mikef.*/
          )
        }
      end
    end
  end
end
