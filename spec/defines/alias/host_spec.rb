require 'spec_helper'
require 'support/supported_os_facts'

describe 'sudo::alias::host' do
  context 'supported operating systems' do
    supported_os_facts.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        let(:title) { 'host_rspec' }

        let(:params) { { content: ['1.2.3.4', '5.6.7.8'], comment: 'generic comment' } }

        it do
          is_expected.to contain_sudo__alias('host_rspec').with(
            'content'    => ['1.2.3.4', '5.6.7.8'],
            'order'      => 12,
            'comment'    => 'generic comment',
            'alias_type' => 'host',
          )
        end
      end
    end
  end
end
