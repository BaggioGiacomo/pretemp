class Admin::TemplateCategoriesController < AdminController
  before_action :set_template_category, only: [ :edit, :update, :destroy ]

  def index
    @template_categories = TemplateCategory.all
  end

  def new
    @template_category = TemplateCategory.new
  end

  def create
    @template_category = TemplateCategory.new(template_category_params)

    if @template_category.save
      redirect_to admin_template_categories_path, notice: "Categoria creata con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @template_category.update(template_category_params)
      redirect_to admin_template_categories_path, notice: "Categoria aggiornata con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template_category.destroy
    redirect_to admin_template_categories_path, notice: "Categoria eliminata con successo."
  end

  private

    def set_template_category
      @template_category = TemplateCategory.find(params[:id])
    end

    def template_category_params
      params.require(:template_category).permit(:name, :description)
    end
end
