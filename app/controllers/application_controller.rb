# -*- encoding : utf-8 -*-
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  include Hobo::AuthenticationSupport
  #  before_filter :login_required

  def fill_drop_down
#    @organizations = Organization.all
#    @people = Person.all
    @o_to_o_types = OToORelationType.visual.not_parsed + OToORelationType.litig.not_parsed
    @p_to_p_types = PToPRelationType.not_internal.not_parsed
    @p_to_o_types = PToORelationType.not_parsed
    @info_sources = InformationSource.not_internal
    @recent_articles = Article.limit(0)
  end

before_filter :set_locale
 
def set_locale
  #I18n.locale = extract_locale_from_subdomain || I18n.default_locale
  I18n.locale = extract_locale_from_subdomain
end  

def extract_locale_from_subdomain
  parsed_locale = request.subdomains.first
  parsed_locale == "en" ? parsed_locale : "hu"
  #parsed_locale = "en"
end  
  
end

