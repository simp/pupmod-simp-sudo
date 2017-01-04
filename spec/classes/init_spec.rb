require 'spec_helper'

describe 'sudo' do

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts
      end

      it { should create_class('sudo') }

      it do
        should contain_simpcat_build('sudoers').with({
          'order' => ['remote_sudoers', '*.alias', '*.default', '*.uspec'],
          'target' => '/etc/sudoers',
          #'onlyif' => Output of concat build
        })
      end

      it do
        should contain_file('/etc/sudoers').with({
          'ensure'    => 'file',
          'owner'     => 'root',
          'group'     => 'root',
          'mode'      => '0440',
          'backup'    => false,
          'audit'     => 'content',
          'subscribe' => 'Simpcat_build[sudoers]',
          'require'   => 'Package[sudo]'
        })
      end

      it { should contain_package('sudo') }
    end
  end
end
