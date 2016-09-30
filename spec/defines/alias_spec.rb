require 'spec_helper'

describe 'sudo::alias' do

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
