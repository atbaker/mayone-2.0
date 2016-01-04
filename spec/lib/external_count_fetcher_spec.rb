require 'rails_helper'

describe ExternalCountFetcher do
  before(:all) do
    @fake_counts = {supporter_count: 69087, volunteer_count: 2151, called_voters_count: 0, reps_calls_count: 0,
      house_supporters: 0, senate_supporters: 0, donations_total: 748608206, donations_count: 65136,
      letter_signers: 1, recordings_uniq: 10, recordings_total: 20}
  end
  before do
    allow(Activity).to receive_message_chain(:find_by_template_id,:actions,:count).and_return(@fake_counts[:letter_signers])
    allow(Ivr::Recording).to receive_message_chain(:active_recordings, :length).and_return(@fake_counts[:recordings_uniq])
    allow(Ivr::Recording).to receive(:count).and_return(@fake_counts[:recordings_total])
  end

  let(:count_fetcher){ ExternalCountFetcher.new }

  def set_all_keys_to(count:)
    ExternalCountFetcher::REDIS_KEYS.each do |key|
      counter = Redis::Counter.new('external_count_fetcher:true:'+key.to_s)
      counter.value = count
    end
  end

  def counts_hash(count: )
    ExternalCountFetcher::REDIS_KEYS.each_with_object({}){|k,h| h[k] = count }
  end

  context "with redis instance_variables" do
    it "should set redis expiration times" do
      redis = Redis.new
      Timecop.freeze(Time.now - ExternalCountFetcher::REDIS_EXPIRE_SECONDS*2/3) do
        count_fetcher.fetch_empty_counts!
        expect(count_fetcher.house_supporters.ttl).to eq(ExternalCountFetcher::REDIS_EXPIRE_SECONDS)
      end
      Timecop.freeze do
        new_time = (ExternalCountFetcher::REDIS_EXPIRE_SECONDS/3)
        expect(count_fetcher.house_supporters.ttl).to be_within(1).of(new_time)
      end
    end

    it "should extend redis expiration times" do
      redis = Redis.new
      Timecop.freeze do
        Timecop.freeze(Time.now - ExternalCountFetcher::REDIS_EXPIRE_SECONDS*2/3) do
          count_fetcher.fetch_empty_counts!
          expect(count_fetcher.house_supporters.ttl).to eq(ExternalCountFetcher::REDIS_EXPIRE_SECONDS)
        end
        count_fetcher.house_supporters.expire(ExternalCountFetcher::REDIS_EXPIRE_SECONDS)
        expect(count_fetcher.house_supporters.ttl).to eq(ExternalCountFetcher::REDIS_EXPIRE_SECONDS)
      end
    end
  end

  describe "#counts!" do
    it "fetches all" do
      allow(count_fetcher).to receive(:fetch_empty_counts!)
      count_fetcher.counts!
      expect(count_fetcher).to have_received(:fetch_empty_counts!)
    end
    it "returns counts hash" do
      expect(count_fetcher.counts!).to eq(@fake_counts)
    end
  end

  describe "#fetch_empty_counts!" do
    context "with empty redis counter cache" do
      it "calls fetch_count with correct keys" do
        allow(count_fetcher).to receive(:fetch_count)

        count_fetcher.fetch_empty_counts!

        expect(count_fetcher).to have_received(:fetch_count).exactly(ExternalCountFetcher::REDIS_KEYS.length).times
        ExternalCountFetcher::REDIS_KEYS.each do |key|
          expect(count_fetcher).to have_received(:fetch_count).with(counter_key: key, reset: false)
        end
      end
    end
    context "with full redis counter cache" do
      before do
        set_all_keys_to(count: 10)
      end
      it "doesn't fetch_count with correct keys" do
        allow(count_fetcher).to receive(:fetch_count).and_call_original
        count_fetcher.fetch_empty_counts!
        expect(count_fetcher).not_to have_received(:fetch_count)
      end
      it "returns counts hash" do
        expect(count_fetcher.counts).to eq(counts_hash(count: 10))
      end
      context "with reset: true" do
        it "calls fetch_count with reset: false" do
          allow(count_fetcher).to receive(:fetch_count).and_call_original
          allow(count_fetcher).to receive(:fetch_supporter_counts).and_call_original

          count_fetcher.fetch_empty_counts!

          expect(count_fetcher).not_to have_received(:fetch_count).with(reset: false)
          expect(count_fetcher).not_to have_received(:fetch_supporter_counts).with(reset: false)
        end
        it "re-fetches the counts" do
          count_fetcher.fetch_empty_counts!(reset: true)
          expect(count_fetcher.counts).to eq(@fake_counts)
        end
      end
    end
  end

  describe "#counts" do
    context "with empty redis counter cache" do
      it "returns a empty list of counts" do
        expect(ExternalCountFetcher.new.counts).to eq(counts_hash(count: 0))
      end
    end
    context "with full redis counter cache" do
      it "should return proper counts" do
        count_fetcher.fetch_empty_counts!

        expect(count_fetcher.counts).to eq(@fake_counts)
      end
    end
  end

  describe "#fetch_count!" do
    it "fetches a donations_count" do
      allow(Integration::PledgeService).to receive(:donations_count)
      count_fetcher.__send__(:fetch_count, counter_key: :donations_count)
      expect(Integration::PledgeService).to have_received(:donations_count)
    end
    it "fetches a donations_total" do
      allow(Integration::PledgeService).to receive(:donations_total)
      count_fetcher.__send__(:fetch_count, counter_key: :donations_total)
      expect(Integration::PledgeService).to have_received(:donations_total)
    end
    it "fetches a supporter_count" do
      allow(count_fetcher).to receive(:fetch_supporter_counts)
      count_fetcher.__send__(:fetch_count, counter_key: :supporter_count)

      expect(count_fetcher).to have_received(:fetch_supporter_counts)
    end
    context "with reset:true" do
      it "resets expiration times" do
        Timecop.freeze(Time.now - 2.hours) do
          count_fetcher.fetch_empty_counts!
        end
        redis = Redis.new
        key = count_fetcher.house_supporters.key

        Timecop.freeze do
          count_fetcher.__send__(:fetch_count, counter_key: :donations_count, reset: true)
          expect(count_fetcher.donations_count.ttl).to eq(ExternalCountFetcher::REDIS_EXPIRE_SECONDS)
        end
      end
    end
  end

end
