require 'spec_helper'

describe 'sudo::user_specification' do

  let(:title) { 'user_specification_spec' }

  let(:params) { {:user_list => 'joe, jimbob', :cmnd => ['ifconfig']} }

  it do
    should contain_concat_fragment('sudoers+user_specification_spec.uspec') \
      .with_content(/.*joe, jimbob(\s*|.*)PASSWD.*EXEC.*ifconfig/)
  end

end
