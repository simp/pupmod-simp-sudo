require 'spec_helper'

describe 'sudo::alias::cmnd' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        let(:title) { 'my_alias' }

        let(:params) { { content: ['/usr/sbin/shutdown, /usr/sbin/reboot'], comment: 'generic comment' } }

        it do
          is_expected.to contain_sudo__alias('my_alias').with(
            'content'    => ['/usr/sbin/shutdown, /usr/sbin/reboot'],
            'order'      => 10,
            'comment'    => 'generic comment',
            'alias_type' => 'cmnd',
          )
        end
      end
    end
  end
end
