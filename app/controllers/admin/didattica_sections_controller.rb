class Admin::DidatticaSectionsController < AdminController
  before_action :set_section, only: [ :edit, :update, :destroy ]

  def index
    @didattica_sections = DidatticaSection.ordered
  end

  def new
    @didattica_section = DidatticaSection.new(position: DidatticaSection.next_free_position)
  end

  def create
    @didattica_section = DidatticaSection.new(section_params)

    if @didattica_section.save
      redirect_to admin_didattica_sections_path, notice: "Sezione creata con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @didattica_section.update(section_params)
      redirect_to admin_didattica_sections_path, notice: "Sezione aggiornata con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @didattica_section.destroy
    redirect_to admin_didattica_sections_path, notice: "Sezione eliminata con successo."
  end

  private

    def set_section
      @didattica_section = DidatticaSection.find(params[:id])
    end

    def section_params
      params.require(:didattica_section).permit(:name, :description, :position)
    end
end
