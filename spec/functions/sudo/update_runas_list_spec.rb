require 'spec_helper'

describe 'sudo::update_runas_list' do
  context 'with no ALL in input' do
    # rubocop:disable RSpec/RepeatedDescription
    it 'returns the same array' do
      input = [ 'you', 'me', 'I' ]
      is_expected.to run.with_params(input).and_return(input)
    end
    it 'returns the same array' do
      input = [ '%you' ]
      is_expected.to run.with_params(input).and_return(input)
    end
    # rubocop:enable RSpec/RepeatedDescription
  end
  context 'with string as input should return an array' do
    it 'returns the same array' do
      input = 'you'
      output = [ 'you' ]
      is_expected.to run.with_params(input).and_return(output)
    end
  end
  context 'with string ALL as input should add !#-1' do
    it 'returns the same array' do
      input = 'ALL'
      output = [ 'ALL', '!#-1' ]
      is_expected.to run.with_params(input).and_return(output)
    end
  end
  context 'with string %ALL as input should add !%#-1' do
    it 'returns the same array' do
      input = '%ALL'
      output = [ '%ALL', '!%#-1' ]
      is_expected.to run.with_params(input).and_return(output)
    end
  end
  context 'with ALL in the  array' do
    it 'returns the array with !#-1' do
      input = [ 'ALL', '!root' ]
      output = [ 'ALL', '!root', '!#-1' ]
      is_expected.to run.with_params(input).and_return(output)
    end
    it 'does not duplicate #!-1' do
      input = [ 'ALL', '!root', '!#-1' ]
      is_expected.to run.with_params(input).and_return(input)
    end
  end
  context 'with %ALL in the  array' do
    it 'returns the array with !#-1' do
      input = [ '%ALL' ]
      output = [ '%ALL', '!%#-1' ]
      is_expected.to run.with_params(input).and_return(output)
    end
    it 'does not duplicate !%#-1' do
      input = [ '%ALL', '!%#-1' ]
      is_expected.to run.with_params(input).and_return(input)
    end
  end
  context 'with %ALL and ALL in the  array' do
    it 'returns the array with !#-1' do
      input = [ '%ALL', 'ALL' ]
      output = ['%ALL', 'ALL', '!#-1', '!%#-1']
      is_expected.to run.with_params(input).and_return(output)
    end
    it 'does not duplicate !#%-1 or !#-1' do
      input = [ '%ALL', '!%#-1', 'ALL', '!#-1']
      is_expected.to run.with_params(input).and_return(input)
    end
  end
end
