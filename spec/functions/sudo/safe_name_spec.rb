require 'spec_helper'
require 'digest'

describe 'sudo::safe_name' do
  it 'returns a clean title unchanged' do
    is_expected.to run.with_params('admin_users-01').and_return('admin_users-01')
  end

  it 'sanitizes and appends a digest when the title contains other characters' do
    digest = Digest::SHA256.hexdigest('admin.users')[0, 8]
    is_expected.to run.with_params('admin.users').and_return("admin_users_#{digest}")
  end

  it 'keeps titles that sanitize identically distinct' do
    digest = Digest::SHA256.hexdigest('admin.users')[0, 8]
    is_expected.to run.with_params('admin_users').and_return('admin_users')
    is_expected.to run.with_params('admin.users').and_return("admin_users_#{digest}")
  end
end
