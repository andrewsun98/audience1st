require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include ActiveMerchant::Billing

describe Store, "Purchasing" do
  self.use_transactional_fixtures = false # to test if rollback works
  before(:each) do
    @amount = 12.35
    @success = ActiveMerchant::Billing::Response.new(true, "Success",
      :transaction_id => "999")
    @failure = ActiveMerchant::Billing::Response.new(false, "Failure")
    @bill_to = Customer.create!(:first_name => "John",
      :last_name => "Doe", :street => "123 Fake St",
      :email => "john@yahoo.com", :day_phone => "212-555-5555",
      :city => "New York", :state => "NY", :zip => "10019")
    @order_num = "789"
    @cc = CreditCard.new(:first_name => @bill_to.first_name,
      :last_name => @bill_to.last_name,
      :month => "12", :year => "2020", :verification_value => "999")
    @cc_params = {:credit_card => @cc,
      :bill_to => @bill_to, :order_number => @order_num}
    @params = {:order_id => @order_num, :email => @bill_to.email,
      :billing_address => {:name => @bill_to.full_name,
        :address1 => @bill_to.street, :city => @bill_to.city,
        :state => @bill_to.state, :zip => @bill_to.zip,
        :phone => @bill_to.day_phone, :country => 'US'}}
  end
  after(:each) do
    @bill_to.destroy
  end

  describe "payment routing" do
    it "should route to correct handler for cash" do
      Store.should_receive(:purchase_with_cash!)
      Store.purchase!(:cash, @amount, {}) 
    end
    it "should route to correct handler for check" do
      Store.should_receive(:purchase_with_check!)
      Store.purchase!('check', @amount, {})
    end
    it "should return failure if payment method invalid" do
      @resp = Store.purchase!('foo', @amount, {}) 
      @resp.should be_a(ActiveMerchant::Billing::Response)
      @resp.should_not be_success
    end
    it "should return failure if params is nil" do
      @resp = Store.purchase!(:cash, @amount, nil)
      @resp.should be_a(ActiveMerchant::Billing::Response)
      @resp.should_not be_success
    end
  end
  
  context "with credit card" do
    it "should route to the credit card payment method" do
      Store.should_receive(:purchase_with_credit_card!)
      Store.purchase!(:credit_card, @amount, {}) do
      end
    end
    it "should call the gateway with correct payment info" do
      Store.should_receive(:pay_via_gateway).with(@amount,@cc, @params).
        and_return(@success)
      Store.purchase!(:credit_card, @amount, @cc_params) do
      end
    end

    context "successfully" do
      before(:each) do
        Store.should_receive(:pay_via_gateway).with(@amount,@cc, @params).
          and_return(@success)
      end
      it "should record side effects to the database"  do
        Store.purchase!(:credit_card, @amount, @cc_params) do
          @bill_to.email = "New@email.com"
          @bill_to.save!
        end
        @bill_to.email.should == "New@email.com"
      end
      it "should return success" do
        @resp = Store.purchase!(:credit_card, @amount, @cc_params) do
        end
        @resp.should be_a(ActiveMerchant::Billing::Response)
        @resp.should be_success
      end
    end
    context "unsuccessfully" do
      it "should not perform side effects if purchase fails"  do
        old_email = @bill_to.email
        Store.should_receive(:pay_via_gateway).with(@amount,@cc,@params).
          and_return(@failure)
        @resp = Store.purchase!(:credit_card, @amount, @cc_params) do
          @bill_to.email = "Change@email.com"
        end
        @bill_to.reload
        @bill_to.email.should == old_email
        @resp.should be_a(ActiveMerchant::Billing::Response)
        @resp.should_not be_success
      end
      it "should not do purchase if side effects fail" do
        Store.should_not_receive(:pay_via_gateway)
        @resp = Store.purchase!(:credit_card, @amount, @cc_params) do
          raise "Boom!"
        end
        @resp.should be_a(ActiveMerchant::Billing::Response)
        @resp.should_not be_success
      end
      it "should not change the database if side effects fail" do
        old_email = @bill_to.email
        @resp = Store.purchase!(:credit_card, @amount, @cc_params) do
          @bill_to.email = "InvalidEmail"
          @bill_to.save!
        end
        @bill_to.reload
        @bill_to.email.should == old_email
        @resp.should be_a(ActiveMerchant::Billing::Response)
        @resp.should_not be_success
      end
    end
  end

  context "with non-credit-card payment" do
    context "unsuccessfully" do
      describe "unsuccessful side effects",:shared=>true do
        it "should not change the database if side effects fail" do
          old_email = @bill_to.email
          Store.purchase!(@method, @amount, {}) do
            @bill_to.email = "InvalidEmailWillThrowError"
            @bill_to.save!
          end
          @bill_to.reload
          @bill_to.email.should == old_email
        end
        it "should return failure if side effects fail" do
          @resp = Store.purchase!(@method,@amount,@args) do
            raise "Boom!"
          end
          @resp.should be_a(ActiveMerchant::Billing::Response)
          @resp.should_not be_success
        end
      end
      describe "using cash" do
        before(:each) do ; @method = :cash ; end
        it_should_behave_like "unsuccessful side effects"
      end
      describe "using check" do
        before(:each) do ; @method = :check ; end
        it_should_behave_like "unsuccessful side effects"
      end
    end
    context "successfully" do
      it "should return success" do
        @resp = Store.purchase!(:cash,@amount,{})
        @resp.should be_a(ActiveMerchant::Billing::Response)
        @resp.should be_success
      end
      it "should change the database if side effects OK" do
        new_email = "valid@email.address.com"
        @resp = Store.purchase!(:cash,@amount,{}) do
          @bill_to.email = new_email
          @bill_to.save!
        end
        @bill_to.reload
        @bill_to.email.should == new_email
      end
    end
  end
end