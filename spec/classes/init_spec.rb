require 'spec_helper'

describe 'sudo' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts
      end

      it { should create_class('sudo') }

      it do
        should contain_concat('/etc/sudoers')
      end

      it { should contain_package('sudo') }
    end
  end
end
