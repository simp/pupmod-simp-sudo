require 'spec_helper_acceptance'

test_name 'sudo class'

describe 'sudo class' do
  let(:files_dir) { File.join(File.dirname(__FILE__), 'files') }
  let(:script1) { '/usr/sbin/sudo_test_script1' }
  let(:script2) { '/usr/sbin/sudo_test_script2' }
  let(:user1) { 'testuser1' }
  let(:user2) { 'testuser2' }
  let(:group1) { 'testgroup1' }
  let(:password) { 'T3stT3stP@ssw0rd' }

  let(:manifest) do
    <<-EOS
   include 'sudo'

   sudo::user_specification { "group1_sudo_access":
      user_list => ["%#{group1}"],
      runas     => 'root',
      cmnd      => ["#{script1}"],
      passwd    => false
    }
   sudo::alias { 'USERALIAS':
      alias_type => 'user',
      content    => ["#{user2}"]
      }

  sudo::alias { 'CMDALIAS':
     alias_type => 'cmnd',
     content    => ["#{script2}","#{script1}"]
     }

   sudo::user_specification { "user2_sudo_access":
      user_list => ['USERALIAS'],
      runas     => 'root',
      cmnd      => ['CMDALIAS'],
      passwd    => false
    }
    #set the users to be able to run sudo without tty
    sudo::default_entry {'user_no_tty':
      def_type => 'user',
      content  => ["#{user2},#{user1} !requiretty, visiblepw"]
    }
    #set timeout to 4 seconds so fails don't hang forever
    sudo::default_entry { '00timeout':
      content => [ 'passwd_timeout=0.1']
    }
    EOS
  end

  hosts.each do |host|
    os_version = fact_on(host, 'operatingsystemmajrelease')
    context 'with defaults' do
      it 'creates users' do
        on(host, "openssl passwd #{password}").stdout
        on(host, "groupadd #{group1} -g 5000")
        on(host, "useradd #{user1} -u 1111 -b /home -G #{group1} -m -U")
        on(host, "useradd #{user2} -u 2222 -b /home -m -U ")
      end

      it 'copies test scripts to server' do
        scp_to(host, File.join(files_dir, 'sudo_test_script1'), script1.to_s)
        on(host, "chmod 700 #{script1}; chown root:root #{script1}")
        scp_to(host, File.join(files_dir, 'sudo_test_script2'), script2.to_s)
        on(host, "chmod 700 #{script2}; chown root:root #{script2}")
      end

      it 'does not let users sudo before configuring sudo' do
        if os_version >= '7'
          result1 = on(host, %(runuser - #{user1} sudo #{script1}), accept_all_exit_codes: true)
          result2 = on(host, %(runuser -u #{user2} sudo #{script2}), accept_all_exit_codes: true)
        else
          result1 = on(host, %(runuser  #{user1} -c 'sudo #{script1}'), accept_all_exit_codes: true)
          result2 = on(host, %(runuser  #{user2} -c 'sudo #{script2}'), accept_all_exit_codes: true)
        end

        expect(result1.exit_code).not_to eq(0)
        expect(result2.exit_code).not_to eq(0)
      end

      it 'applies the manifest and work with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'allows user1 to run script1' do
        result = if os_version >= '7'
                   on(host, %(runuser -u #{user1} sudo #{script1}), accept_all_exit_codes: true)
                 else
                   on(host, %(runuser  #{user1} -c "sudo #{script1}"), accept_all_exit_codes: true)
                 end
        expect(result.exit_code).to eq(0)
        expect(result.stdout).to include('It is wonderful')
      end
      it 'allows user2 to run script2 with no passwd' do
        result = if os_version >= '7'
                   on(host, %(runuser -u #{user2} sudo #{script2}), accept_all_exit_codes: true)
                 else
                   on(host, %(runuser  #{user2} -c "sudo #{script2}"), accept_all_exit_codes: true)
                 end
        expect(result.exit_code).to eq(0)
        expect(result.stdout).to include('Hello World')
      end
    end
  end
end
