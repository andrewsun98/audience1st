module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in webrat_steps.rb
  #
  def path_to(page_name)
    case page_name
    when /the login page/i              then '/login'
    when /the home ?page/i              then '/customers/welcome'
    when /the subscriber home ?page/i   then '/customers/welcome'
    when /the edit contact info page for customer "(.*) +(.*)"/i
      @customer = Customer.find_by_first_name_and_last_name($1, $2) or raise ActiveRecord::RecordNotFound
      get "/customers/switch_to/#{@customer.id}"
      "/customers/edit/#{@customer.id}"

    when /the store page/i              then '/store/index'
    when /the subscriptions page/i      then '/store/subscribe'
    when /the donations page/i          then '/donations'
    when /the walkup sales page/i       then "/box_office/walkup/#{@showdate.id}"
    when /the checkin page/i            then "/box_office/checkin/#{@showdate.id}"

    when /the admin:(.*) page/i
      page = $1
      case page
      when /settings/i    then '/options/edit' 
      when /bulk import/i then '/bulk_downloads/new'
      when /import/i      then '/imports/new'
      else                raise "No mapping for admin:#{page}"
      end

    when /the vouchertypes page/i       then '/vouchertypes/list'
    when /the new vouchertypes? page/i  then '/vouchertypes/new'
    when /the new show page/i           then '/shows/new'

    when /the show details page for "(.*)"/i
      @show = Show.find_by_name($1)
      @show.should_not be_nil
      "/shows/edit/#{@show.id}"
    when /the new showdate page for "(.*)"/i
      @show = Show.find_by_name($1)
      "/showdates/new?show_id=#{@show.id}"

    else
      raise "Can't find mapping for \"#{page_name}\" in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
