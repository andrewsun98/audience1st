require 'spec_helper'
describe VoucherPresenter do
  describe 'new' do
    before(:each) do
      @v1 = create(:subscriber_voucher)
      @v2 = create(:subscriber_voucher, :vouchertype => @v1.vouchertype)
    end
    it 'is valid when vouchers belong together' do
      @v1.reserve!(sd = create(:showdate))
      @v2.reserve!(sd, '')
      expect { VoucherPresenter.new([@v1,@v2]) }.to_not raise_error
    end
    it 'is invalid if one is reserved and others not' do
      @v2.reserve!(create(:showdate))
      expect { VoucherPresenter.new([@v1,@v2]) }.to raise_error(VoucherPresenter::InvalidGroupError)
    end
    it 'is invalid if not all same vouchertype' do
      @v1.reserve!(sd = create(:showdate))
      @v2.reserve!(sd)
      @v2.update_attribute(:vouchertype, create(:revenue_vouchertype))
      expect { VoucherPresenter.new([@v1,@v2]) }.to raise_error(VoucherPresenter::InvalidGroupError)
    end      
  end
  describe 'sorting' do
    before(:each) do
      @vt = Array.new(2) { create(:vouchertype_included_in_bundle) }
      @sd = [create(:showdate), create(:showdate, :date => 2.weeks.from_now)]
    end
    describe 'when all vouchertypes are valid for some showdate' do
      # test sort order criteria for same/different vouchertypes, same/different showdates (or no date)
      [
        # v1,v2 s1,s2  <=>   comment
        [  0,0,  0,1, -1,  "same vouchertype, different showdates, second showdate is later"],
        [  0,0,  1,0, 1,   "same vouchertype, different showdates, first showdate is later"],
        [  0,0,  0,0, 0,   "same vouchertype, same showdate"],
        [  0,1,  0,0, -1,  "different vouchertype, same showdate, first vouchertype sorts earlier"],
        [  1,0,  0,0, 1,  "different vouchertype, same showdate, first vouchertype sorts later"],
        [  0,1,  0,1, -1,  "different vouchertype, different showdate, first showdate is earlier"],
        [  0,1,  1,0, 1,  "different vouchertype, different showdate, second showdate is earlier"]
      ].each do |test|
        specify test[5] do
          v0 = create(:revenue_voucher, :vouchertype => @vt[test[0]])
          v0.reserve!(@sd[test[2]]) unless test[2].nil?
          v1 = create(:revenue_voucher, :vouchertype => @vt[test[1]])
          v1.reserve!(@sd[test[3]]) unless test[3].nil?
          (v0 <=> v1).should == test[4]
        end
      end
    end
  end
end
