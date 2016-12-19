require 'spec_helper'
require File.expand_path('../shared_examples', __FILE__)

describe GlobalSession::Session::Abstract do
  include SpecHelper

  before(:all) do
    @key_factory = KeyFactory.new
    @key_factory.create('authority1', true)
    @key_factory.create('authority2', false)
  end

  after(:all) do
    @key_factory.destroy
  end

  context '#generate_id' do
    let(:configuration) { {'attributes' => {'signed' => []}, 'timeout' => 3} }
    let(:directory) { flexmock(GlobalSession::Directory, configuration:configuration, local_authority_name:'todd') }
    subject { GlobalSession::Session::V4 }

    it 'makes unpredictable session IDs' do
        uuids = []
        pos_to_freq = {}

        1_000.times do
          uuids << subject.new(directory).id
        end

        uuids.each do |uuid|
          pos = 0
          uuid.each_char do |char|
            pos_to_freq[pos] ||= {}
            pos_to_freq[pos][char] ||= 0
            pos_to_freq[pos][char] += 1
            pos += 1
          end
        end

        predictable_pos = 0
        total_pos       = 0

        pos_to_freq.each_pair do |pos, frequencies|
          n    = frequencies.size.to_f
          total  = frequencies.values.inject(0) { |x, v| x+v }.to_f
          mean = total / n

          sum_diff_sq = 0.0
          frequencies.each_pair do |char, count|
            sum_diff_sq += (count - mean)**2
          end
          var = (1 / n) * sum_diff_sq
          std_dev = Math.sqrt(var)

          predictable_pos += 1 if std_dev == 0.0
          total_pos += 1
        end

        # None of the character positions should be predictable
        expect(predictable_pos).to eq(0)
      end
  end

  # Find all version-specific subclasses and test that they do useful things.
  DESCENDENTS = []
  ObjectSpace.each_object(Class) do |k|
    DESCENDENTS.unshift k if k < GlobalSession::Session::Abstract
  end
  DESCENDENTS.freeze

  DESCENDENTS.each do |klass|
    context "given a valid serialized #{klass}" do
      let(:subclass) { klass }
      before(:each) do
        mock_config('test/trust', ['authority1'])
        mock_config('test/authority', 'authority1')
        mock_config('test/timeout', 60)
        mock_config('test/attributes/signed', ['user'])
        mock_config('test/attributes/unsigned', ['account'])
        @directory = GlobalSession::Directory.new(mock_config, @key_factory.dir)
        @session = subclass.new(@directory)
      end

      context :to_hash do
        before(:each) do
          @hash = @session.to_hash
        end

        it 'includes metadata' do
          expect(@hash[:metadata][:id]).to eq(@session.id)
          expect(@hash[:metadata][:created_at]).to eq(@session.created_at)
          expect(@hash[:metadata][:expired_at]).to eq(@session.expired_at)
          expect(@hash[:metadata][:authority]).to eq(@session.authority)

          @hash[:signed].each_pair { |k, v| expect(@session[k]).to eq(v) }
          @hash[:insecure].each_pair { |k, v| expect(@session[k]).to eq(v) }
        end
      end
    end
  end
end
