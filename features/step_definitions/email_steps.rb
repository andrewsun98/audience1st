Then /^an email should be sent to( customer)? "(.*?)"( matching "(.*)" with "(.*)")?$/ do |cust,recipient,_,match_var,regex|
  recipient = Customer.find_by_first_name_and_last_name!(*recipient.split(/\s+/)).email if cust
  @email = ActionMailer::Base.deliveries.first
  @email.should_not be_nil
  @email.to.should include(recipient)
  if match_var
    match = @email.body.match( Regexp.new regex )
    match[1].should_not be_nil
    instance_variable_set "@#{match_var}", match[1]
  end
end

Then /^no email should be sent to( customer)? "(.*)"$/ do |cust,recipient|
  recipient = Customer.find_by_first_name_and_last_name!(*recipient.split(/\s+/)).email if cust
  ActionMailer::Base.deliveries.any? { |e| e.to.include?(recipient) }.should be_false
end
