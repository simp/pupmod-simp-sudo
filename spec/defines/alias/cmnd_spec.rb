require 'spec_helper'

describe 'sudo::alias::cmnd' do

  let(:title) { 'my_alias'}

  let(:params) { {:content => ['/usr/sbin/shutdown, /usr/sbin/reboot'], :comment => 'generic comment'} }

  it do
    should contain_sudo__alias('my_alias').with({
      'content' => ['/usr/sbin/shutdown, /usr/sbin/reboot'],
      'order' => '10',
      'comment' => 'generic comment',
      'alias_type' => 'cmnd'
    })
  end

end
