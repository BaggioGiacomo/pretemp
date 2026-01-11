class TemplatesController < ApplicationController
  def index
    @categories = TemplateCategory.all
  end

  def show
    @category = TemplateCategory.find params[:category]
    @templates = @category.templates
  end
end
