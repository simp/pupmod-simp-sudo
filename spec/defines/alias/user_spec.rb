require 'spec_helper'
require 'support/supported_os_facts'

describe 'sudo::alias::user' do
  context 'supported operating systems' do
    supported_os_facts.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }
        let(:title) { 'user_rspec' }

        let(:params) { { content: ['millert', 'mikef'], comment: 'generic comment' } }

        it do
          is_expected.to contain_sudo__alias('user_rspec').with(
            'content'    => ['millert', 'mikef'],
            'order'      => 16,
            'comment'    => 'generic comment',
            'alias_type' => 'user',
          )
        end
      end
    end
  end
end
