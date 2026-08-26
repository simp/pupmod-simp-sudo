require 'spec_helper_acceptance'

test_name 'upgrade from sudo module 6.x'

# Simulates a system that was managed by pupmod-simp-sudo 6.x, where
# /etc/sudoers was a module-owned concat of exactly the rendered entries
# (no OS-shipped Defaults, no #includedir) and no drop-in files existed,
# then applies the 7.x manifest and verifies the transition is automatic:
# the includedir directive is appended, the legacy lines are cleaned up,
# the drop-ins carry the policy, and sudo works throughout.
describe 'upgrade from sudo module 6.x' do
  # rubocop:disable RSpec/IndexedLet
  let(:script1) { '/usr/sbin/sudo_test_script1' }
  let(:script2) { '/usr/sbin/sudo_test_script2' }
  let(:user1) { 'testuser1' }
  let(:user2) { 'testuser2' }
  let(:group1) { 'testgroup1' }
  # rubocop:enable RSpec/IndexedLet

  # Same declarations as 00_default_spec.rb: 6.x rendered these into
  # /etc/sudoers with the same templates, so the simulated monolith below
  # is byte-identical to what 6.x would have left behind.
  let(:manifest) do
    <<~EOS
      include 'sudo'

      sudo::user_specification { "group1_sudo_access":
        user_list => ["%#{group1}"],
        runas     => 'root',
        cmnd      => ["#{script1}"],
        passwd    => false,
      }
      sudo::alias { 'USERALIAS':
        alias_type => 'user',
        content    => ["#{user2}"],
      }

      sudo::alias { 'CMDALIAS':
        alias_type => 'cmnd',
        content    => ["#{script2}","#{script1}"],
      }

      sudo::user_specification { "user2_sudo_access":
        user_list => ['USERALIAS'],
        runas     => 'root',
        cmnd      => ['CMDALIAS'],
        passwd    => false,
      }
      sudo::default_entry {'user_no_tty':
        def_type => 'user',
        content  => ["#{user2},#{user1} !requiretty, visiblepw"],
      }
      sudo::default_entry { '00timeout':
        content => [ 'passwd_timeout=0.1'],
      }
    EOS
  end

  hosts.each do |host|
    context 'given a 6.x-style module-owned /etc/sudoers' do
      it 'reconstructs the 6.x end state from the current drop-ins' do
        # 6.x concat-ordered fragments: aliases (10), defaults (80),
        # user specifications (90). The drop-in prefixes preserve that
        # order, so concatenating them in glob order reproduces the file.
        on(host, 'cat /etc/sudoers.d/0010_* /etc/sudoers.d/0080_* /etc/sudoers.d/0090_* > /etc/sudoers.6x')
        on(host, 'install -o root -g root -m 0440 /etc/sudoers.6x /etc/sudoers && rm -f /etc/sudoers.6x')
        on(host, 'rm -f /etc/sudoers.d/0010_* /etc/sudoers.d/0080_* /etc/sudoers.d/0090_* /etc/sudoers.d/1000_*')
      end

      it 'still grants access via the monolithic file (pre-upgrade sanity)' do
        result = on(host, %(runuser -u #{user2} sudo #{script2}), accept_all_exit_codes: true)
        expect(result.exit_code).to eq(0)
      end

      it 'applies the 7.x manifest without errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'appended exactly one includedir directive' do
        result = on(host, %(grep -c '^#includedir /etc/sudoers.d$' /etc/sudoers))
        expect(result.stdout.strip).to eq('1')
      end

      it 'removed the legacy entry lines from /etc/sudoers' do
        on(host, %(grep -F 'User_Alias USERALIAS' /etc/sudoers), acceptable_exit_codes: [1])
        on(host, %(grep -F 'Cmnd_Alias CMDALIAS' /etc/sudoers), acceptable_exit_codes: [1])
        on(host, %(grep -F 'passwd_timeout=0.1' /etc/sudoers), acceptable_exit_codes: [1])
      end

      it 'moved the policy into drop-in files' do
        on(host, 'test -f /etc/sudoers.d/0010_user_alias_USERALIAS')
        on(host, 'test -f /etc/sudoers.d/0090_uspec_user2_sudo_access')
      end

      it 'passes a strict whole-config parse' do
        on(host, '/usr/sbin/visudo -csf /etc/sudoers')
      end

      it 'still grants the same access after the upgrade' do
        result = on(host, %(runuser -u #{user2} sudo #{script2}), accept_all_exit_codes: true)
        expect(result.exit_code).to eq(0)
        expect(result.stdout).to include('Hello World')
      end
    end
  end
end
