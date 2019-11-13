# This function is used to help mitigate CVE-2019-14287 for
#  sudo version prior to 1.8.28.  It will disallow userid/groupid
#  of -1 if ALL or %ALL is used.
#
Puppet::Functions.create_function(:'sudo::update_runas_list') do

  # @param content
  #  An array of users/groups to add to a Runas_list in sudo
  #
  # @return [Array[String]]
  #  An Array of users to add to a Runas_list in sudo that
  #  appends not -1 if 'ALL' or '%ALL' are used to avoid
  #  giving unintentional root access or skip auditing.
  #
  # Note: Added even if !root is not present because it will skip over
  # some auditing if #-1 is used.
  dispatch :update_runas_list do
    required_param 'Array[String]', :content
  end

  # @param content
  #  A string of one user/group id to to Runas_list.
  #
  # @return [Array[String]]
  #  An Array of users to add to a Runas_list in sudo that
  #  appends not -1 if 'ALL' or '%ALL' are used to avoid
  #  giving unintentional root access or skip auditing.
  #
  # Note: Added even if !root is not present because it will skip over
  # some auditing if #-1 is used.
  dispatch :update_runas_list_string do
    required_param 'String', :content
  end

  def update_runas_list(content)

    output = content.dup

    if content.member?('ALL')
      output << '!#-1'
    end
    if content.member?('%ALL')
      output << '!%#-1'
    end

    output.uniq

  end

  def update_runas_list_string(content)
    output = Array.new
    output << content
    update_runas_list(output)
  end

end
