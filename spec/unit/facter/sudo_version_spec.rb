require 'spec_helper'

describe 'sudo_version' do
  before :each do
    Facter.clear
  end

  context 'sudo command exists' do
    it 'returns the correct version of sudo when sudo is executable' do
      allow(Facter::Util::Resolution).to receive(:which).with('sudo').and_return('/bin/sudo')
      allow(File).to receive(:executable?).with('/bin/sudo').and_return(true)
      allow(File).to receive(:exists?).with('/bin/sudo').and_return(true)
      allow(Facter::Core::Execution).to receive(:execute).with('/bin/sudo -V').and_return(
        "Sudo Version 1.2.3\nMorej junk 5.6.7\nLast bit  8.9.0\n\n",
      )
      expect(Facter.fact(:sudo_version).value).to eq('1.2.3')
    end

    it 'returns nil when sudo is not executable' do
      allow(Facter::Util::Resolution).to receive(:which).with('sudo').and_return('/bin/sudo')
      allow(File).to receive(:executable?).with('/bin/sudo').and_return(false)
      allow(File).to receive(:exists?).with('/bin/sudo').and_return(true)
      expect(Facter.fact(:sudo_version).value).to eq(nil)
    end

    it 'returns nil when sudo does not exist' do
      allow(Facter::Util::Resolution).to receive(:which).with('sudo').and_return(nil)
      expect(Facter.fact(:sudo_version).value).to eq(nil)
    end
  end
end
