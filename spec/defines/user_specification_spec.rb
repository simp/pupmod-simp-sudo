require 'spec_helper'

describe 'sudo::user_specification' do

  let(:title) { 'user_specification_spec' }

  let(:params) { {:user_list => 'joe, jimbob, %foo', :cmnd => ['ifconfig']} }

  it do
    should contain_simpcat_fragment('sudoers+user_specification_spec.uspec') \
      .with_content(/.*joe, jimbob, %foo(\s*|.*)PASSWD.*EXEC.*ifconfig/)
  end

end
