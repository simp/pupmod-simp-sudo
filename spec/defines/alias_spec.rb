require 'spec_helper'

describe 'sudo::alias' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts){ os_facts }


        context 'default parameters' do
          let(:title) { :user_alias1 }
          let(:params) {{
            :content    => ['millert', 'mikef'],
            :alias_type => 'user'
          }}

          it { should compile.with_all_deps }
          it {
            should contain_simpcat_fragment('sudoers+user_user_alias1_10.alias').with_content(
              "\nUser_Alias USER_ALIAS1 = millert, mikef\n\n"
            )
          }
        end

        context 'with comment specified' do
          let(:title) { :runas_alias7 }
          let(:params) {{
            :content    => ['millert', 'mikef'],
            :alias_type => 'runas',
            :comment   => 'generic comment'
          }}

          it { should compile.with_all_deps }
          it {
            should contain_simpcat_fragment('sudoers+runas_runas_alias7_10.alias').with_content(
              "#generic comment\n\nRunas_Alias RUNAS_ALIAS7 = millert, mikef\n\n"
            )
          }
        end
      end
    end
  end
end
