# -*- encoding : utf-8 -*-
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def commify(v) 
    a = (s=v.to_s;x=s.length;s).rjust(x+(3-(x%3))).scan(/.{3}/).join('.').strip
    if a[0] == 46
      a = a[1..-1]
    end
    a
  end

  def get_sort_param attr, default_order = 'asc'
    # default_order: az az alapállapot ami első rákattintásnál történik
    if default_order == 'desc'
      "#{@sort_field != attr || @sort_field == attr && @sort_direction == 'desc' ? '' : '-'}#{attr}"
    else
      "#{@sort_field != attr || @sort_field == attr && @sort_direction == 'asc' ? '-' : ''}#{attr}"
    end
  end

  def google_analytics_js

    content_tag(:script, :type => 'text/javascript') do
      "  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-37427518-1']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();"
    end if Rails.env.production?
  end
end

