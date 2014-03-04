require_relative './spec_helper'

describe 'Benchmark Analysis App' do

  xit 'says hello' do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Hello World')
  end

  xit 'new', js: true do

  end

end