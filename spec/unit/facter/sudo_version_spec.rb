require 'spec_helper'

describe 'sudo_version' do
  before :each do
    Facter.clear
  end

  context 'with sudo -V output' do
    it 'returns the version from the first line' do
      allow(Facter::Core::Execution).to receive(:execute).with('sudo -V', on_fail: nil).and_return(
        "Sudo version 1.9.17p2\nSudoers policy plugin version 1.9.17p2\n",
      )
      expect(Facter.fact(:sudo_version).value).to eq('1.9.17p2')
    end

    it 'keeps the previous behavior for the original fixture output' do
      allow(Facter::Core::Execution).to receive(:execute).with('sudo -V', on_fail: nil).and_return(
        "Sudo Version 1.2.3\nMorej junk 5.6.7\nLast bit  8.9.0\n\n",
      )
      expect(Facter.fact(:sudo_version).value).to eq('1.2.3')
    end
  end

  context 'without sudo -V output' do
    it 'returns nil when the command is not found' do
      allow(Facter::Core::Execution).to receive(:execute).with('sudo -V', on_fail: nil).and_return(nil)
      expect(Facter.fact(:sudo_version).value).to be_nil
    end

    it 'returns nil when the command prints nothing' do
      allow(Facter::Core::Execution).to receive(:execute).with('sudo -V', on_fail: nil).and_return('')
      expect(Facter.fact(:sudo_version).value).to be_nil
    end
  end
end
