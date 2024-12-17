require 'spec_helper'

describe 'sudo::alias' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        context 'default parameters' do
          let(:title) { 'user_alias1' }
          let(:params) do
            {
              content: ['millert', 'mikef'],
           alias_type: 'user'
            }
          end

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_concat__fragment("sudo_#{params[:alias_type]}_alias_#{title}").with_content(
              "User_Alias USER_ALIAS1 = millert, mikef\n",
            )
          }
        end

        context 'with comment specified' do
          let(:title) { 'runas_alias7' }
          let(:params) do
            {
              content: ['millert', 'mikef'],
           alias_type: 'runas',
           comment: 'generic comment'
            }
          end

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_concat__fragment("sudo_#{params[:alias_type]}_alias_#{title}").with_content(
              "#generic comment\nRunas_Alias RUNAS_ALIAS7 = millert, mikef\n",
            )
          }
        end

        context 'test cve_2019_14287 mitigaction' do
          let(:title) { 'runas_All' }
          let(:params) do
            {
              content: ['ALL', '!mikef'],
           alias_type: 'runas',
           comment: 'generic comment'
            }
          end

          context 'with version < 1.8.28 and ALL included in content' do
            let(:facts) { os_facts.merge({ sudo_version: '1.8.18' }) }

            it {
              is_expected.to contain_concat__fragment("sudo_#{params[:alias_type]}_alias_#{title}").with_content(
                "#generic comment\nRunas_Alias RUNAS_ALL = ALL, !mikef, !#-1\n",
              )
            }
          end
          context 'with version >= 1.8.28 and ALL included in content' do
            let(:facts) { os_facts.merge({ sudo_version: '1.8.28' }) }

            it {
              is_expected.to contain_concat__fragment("sudo_#{params[:alias_type]}_alias_#{title}").with_content(
                "#generic comment\nRunas_Alias RUNAS_ALL = ALL, !mikef\n",
              )
            }
          end
        end
      end
    end
  end
end
