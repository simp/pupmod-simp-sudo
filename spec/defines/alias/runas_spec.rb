require 'spec_helper'

describe 'sudo::alias::runas' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do

        context 'test with comment' do
          let(:facts){ os_facts }
          let(:title) { 'runas_rspec' }
          let(:params) { {:content => ['millert', 'mikef'], :comment => 'generic comment'} }
          it do
            is_expected.to contain_sudo__alias('runas_rspec').with({
              'content'    => ['millert', 'mikef'],
              'order'      => 14,
              'comment'    => 'generic comment',
              'alias_type' => 'runas'
          })
          end
        end
      end
    end
  end
end
