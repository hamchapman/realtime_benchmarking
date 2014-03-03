require_relative './spec_helper'

describe 'Benchmark Analysis App' do

  it 'says hello' do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Hello World')
  end

end