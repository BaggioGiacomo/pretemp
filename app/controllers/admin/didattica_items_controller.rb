class Admin::DidatticaItemsController < AdminController
  before_action :set_section
  before_action :set_item, only: [ :edit, :update, :destroy ]

  def index
    @didattica_items = @didattica_section.didattica_items
  end

  def new
    @didattica_item = @didattica_section.didattica_items.build(position: DidatticaItem.next_free_position(@didattica_section))
  end

  def create
    @didattica_item = @didattica_section.didattica_items.build(item_params)

    if @didattica_item.save
      redirect_to admin_didattica_section_didattica_items_path(@didattica_section), notice: "Elemento creato con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if params.dig(:didattica_item, :remove_pdf) == "1"
      @didattica_item.pdf.purge
    end

    if @didattica_item.update(item_params)
      redirect_to admin_didattica_section_didattica_items_path(@didattica_section), notice: "Elemento aggiornato con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @didattica_item.destroy
    redirect_to admin_didattica_section_didattica_items_path(@didattica_section), notice: "Elemento eliminato con successo."
  end

  private

    def set_section
      @didattica_section = DidatticaSection.find(params[:didattica_section_id])
    end

    def set_item
      @didattica_item = @didattica_section.didattica_items.find(params[:id])
    end

    def item_params
      params.require(:didattica_item).permit(:title, :url, :position, :pdf)
    end
end
