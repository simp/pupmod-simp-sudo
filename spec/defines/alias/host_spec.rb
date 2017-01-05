require 'spec_helper'

describe 'sudo::alias::host' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts){ os_facts }

        let(:title) { 'host_rspec' }

        let(:params) { {:content => ['1.2.3.4', '5.6.7.8'], :comment => 'generic comment'} }

        it do
          should contain_sudo__alias('host_rspec').with({
            'content'    => ['1.2.3.4', '5.6.7.8'],
            'order'      => 12,
            'comment'    => 'generic comment',
            'alias_type' => 'host'
          })
        end
      end
    end
  end

end
