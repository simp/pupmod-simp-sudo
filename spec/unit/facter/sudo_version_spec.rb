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

    {
      'EL 9'         => ['Sudo version 1.9.5p2', '1.9.5p2'],
      'Ubuntu 22.04' => ['Sudo version 1.9.9', '1.9.9'],
      'Ubuntu 24.04' => ['Sudo version 1.9.15p5', '1.9.15p5'],
    }.each do |platform, (first_line, version)|
      it "parses the #{platform} version string" do
        allow(Facter::Util::Resolution).to receive(:which).with('sudo').and_return('/usr/bin/sudo')
        allow(File).to receive(:executable?).with('/usr/bin/sudo').and_return(true)
        allow(Facter::Core::Execution).to receive(:execute).with('/usr/bin/sudo -V').and_return(
          "#{first_line}\nSudoers policy plugin version #{version}\n",
        )
        expect(Facter.fact(:sudo_version).value).to eq(version)
      end
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
