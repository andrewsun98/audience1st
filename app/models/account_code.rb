class AccountCode < ActiveRecord::Base
  has_many :donations

  def self.default_account_code_id
    self.default_account_code.id
  end
  
  def self.default_account_code
    AccountCode.find(:first) ||
      AccountCode.create!(:name => "General Fund",
      :code => '0000',
      :description => "General Fund")
  end

  # convenience accessor

  def fund_with_account_code
    self.account_code.blank? ? self.name : "#{self.name} (#{self.account_code})"
  end
end
