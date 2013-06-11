# -*- encoding : utf-8 -*-
class InterorgRelationsController < ApplicationController

  hobo_model_controller

  auto_actions :all #, :index, :show

  caches_page :show,  :expires_in => 180.minutes
  caches_page :index, :expires_in => 180.minutes
  caches_page :list,  :expires_in => 180.minutes

  def show
    @this = find_instance
    respond_to do |format| 
      format.html  { hobo_show @this }
      format.xml   { render(:xml => @this) }
      format.json  { render(:json=> @this) }
    end
  end

  def index
    @this = InterorgRelation.not_mirror.value_is_not('').order_by(:value, 'desc')
    params[:sort] ||= "value"
    respond_to do |format| 
      format.html do
        hobo_index( @this, :per_page => 20, :include => [:tender, :contract] ) do
          data = []
          @this.each do |rel|
            data << { :name => (rel.name.scan(/./)[0..34].join('')+'...'), :y =>rel.value }
          end
          @h = LazyHighCharts::HighChart.new('pie') do |f|
            f.options[:chart][:defaultSeriesType] = "pie"
            f.options[:title][:text] = "TOP 20 Tranzakció"
            f.series(:data => data)
          end
          puts @h.inspect
        end
      end
      format.xml   { render( :xml  => @this ) and return }
      format.json  { render( :json => @this ) and return }
    end
  end

  index_action :list do  
    params[:page] ||= 1
    @sort_field = params[:sort] || "value"
    @transactions = InterorgRelation.not_mirror.value_is_not('').apply_scopes(:order_by => parse_sort_param(:value, :name, :updated_at, :organization, :o_to_o_relation_type, :related_organization, :information_source)).paginate(:per_page=>20, :page=>params[:page], :include=>[:tender, :contract])
  end

end

