class Admin::TemplatesController < AdminController
  before_action :set_template_category
  before_action :set_template, only: [ :edit, :update, :destroy ]

  def index
    @templates = @template_category.templates
  end

  def new
    @template = @template_category.templates.build
  end

  def create
    @template = @template_category.templates.build(template_params)

    if @template.save
      redirect_to admin_template_category_templates_path(@template_category), notice: "Template creato con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @template.update(template_params)
      redirect_to admin_template_category_templates_path(@template_category), notice: "Template aggiornato con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy
    redirect_to admin_template_category_templates_path(@template_category), notice: "Template eliminato con successo."
  end

  private

    def set_template_category
      @template_category = TemplateCategory.find(params[:template_category_id])
    end

    def set_template
      @template = @template_category.templates.find(params[:id])
    end

    def template_params
      params.require(:template).permit(:name, :url)
    end
end
