require 'spec_helper'

describe 'sudo::update_runas_list' do
  context 'with no ALL in input' do
    it 'should return the same array' do
      input = [ 'you', 'me', 'I' ]
      is_expected.to run.with_params(input).and_return(input)
    end
    it 'should return the same array' do
      input = [ '%you' ]
      is_expected.to run.with_params(input).and_return(input)
    end
  end
  context 'with string as input should return an array' do
    it 'should return the same array' do
      input = 'you'
      output = [ 'you' ]
      is_expected.to run.with_params(input).and_return(output)
    end
  end
  context 'with string ALL as input should add !#-1' do
    it 'should return the same array' do
      input = 'ALL'
      output = [ 'ALL', '!#-1' ]
      is_expected.to run.with_params(input).and_return(output)
    end
  end
  context 'with string %ALL as input should add !%#-1' do
    it 'should return the same array' do
      input = '%ALL'
      output = [ '%ALL', '!%#-1' ]
      is_expected.to run.with_params(input).and_return(output)
    end
  end
  context 'with ALL in the  array' do
    it 'should return the array with !#-1' do
      input = [ 'ALL', '!root' ]
      output = [ 'ALL', '!root', '!#-1' ]
      is_expected.to run.with_params(input).and_return(output)
    end
    it 'should not duplicate #!-1' do
      input = [ 'ALL', '!root','!#-1' ]
      is_expected.to run.with_params(input).and_return(input)
    end
  end
  context 'with %ALL in the  array' do
    it 'should return the array with !#-1' do
      input = [ '%ALL' ]
      output = [ '%ALL', '!%#-1' ]
      is_expected.to run.with_params(input).and_return(output)
    end
    it 'should not duplicate !%#-1' do
      input = [ '%ALL', '!%#-1' ]
      is_expected.to run.with_params(input).and_return(input)
    end
  end
  context 'with %ALL and ALL in the  array' do
    it 'should return the array with !#-1' do
      input = [ '%ALL', 'ALL' ]
      output = ['%ALL', 'ALL', '!#-1', '!%#-1']
      is_expected.to run.with_params(input).and_return(output)
    end
    it 'should not duplicate !#%-1 or !#-1' do
      input = [ '%ALL', '!%#-1' , 'ALL', '!#-1']
      is_expected.to run.with_params(input).and_return(input)
    end
  end
end
