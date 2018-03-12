require 'spec_helper'

describe 'sudo::alias' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts){ os_facts }


        context 'default parameters' do
          let(:title) { 'user_alias1' }
          let(:params) {{
            :content    => ['millert', 'mikef'],
            :alias_type => 'user'
          }}

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_concat__fragment("sudo_#{params[:alias_type]}_alias_#{title}").with_content(
              "\nUser_Alias USER_ALIAS1 = millert, mikef\n\n"
            )
          }
        end

        context 'with comment specified' do
          let(:title) { 'runas_alias7' }
          let(:params) {{
            :content    => ['millert', 'mikef'],
            :alias_type => 'runas',
            :comment    => 'generic comment'
          }}

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_concat__fragment("sudo_#{params[:alias_type]}_alias_#{title}").with_content(
              "#generic comment\n\nRunas_Alias RUNAS_ALIAS7 = millert, mikef\n\n"
            )
          }
        end
      end
    end
  end
end
