require 'spec_helper'

describe 'sudo::alias::user' do

  let(:title) { 'user_rspec' }

  let(:params) { {:content => ['millert', 'mikef'], :comment => 'generic comment'} }

  it do
    should contain_sudo__alias('user_rspec').with({
      'content' => ['millert', 'mikef'],
      'order' => '10',
      'comment' => 'generic comment',
      'alias_type' => 'user'
    })
  end

end
