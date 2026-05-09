class CreateDidatticaSectionsAndItems < ActiveRecord::Migration[8.1]
  def up
    create_table :didattica_sections do |t|
      t.string  :name, null: false
      t.text    :description
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    create_table :didattica_items do |t|
      t.references :didattica_section, null: false, foreign_key: { on_delete: :cascade }
      t.string  :title, null: false
      t.string  :url
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    seed_existing_data
  end

  def down
    drop_table :didattica_items
    drop_table :didattica_sections
  end

  private

    def seed_existing_data
      sections = [
        {
          name: "Documenti generali",
          items: [
            { title: "Forecasting severe convective storms", url: "http://www.estofex.org/guide/" },
            { title: "A climatology of thunderstorms across Europe from a synthesis of multiple data sources", url: "https://journals.ametsoc.org/doi/pdf/10.1175/JCLI-D-18-0372.1" },
            { title: "Guida sull'uso delle mappe modellistiche (di Oscar Van Der Velde)", url: "/didattica/ConvectiveWeatherMapsVANDERVELDE.pdf" },
            { title: "I tornado (di tornadoseeker.com)", url: "/didattica/tornadodidattica1.pdf" },
            { title: "Examination of severe thunderstorm outbreaks in Central Europe — Helge Tuschy, ESTOFEX e DWD forecaster", url: "http://www.estofex.org/files/tuschy_thesis.pdf" },
            { title: "Previsione trombe marine", url: "https://www.pretemp.altervista.org/swi.html" },
            { title: "Tornado di Pianiga, Dolo e Mira — 8 luglio 2015", url: "http://documenti.serenissimameteo.it/tornado_riviera_brenta.html" },
            { title: "Circuito elettrico dell'atmosfera", url: "/didattica/Elettr-Atm.pdf" },
            { title: "Relazione tra raggi cosmici, nuvolosità e clima — K. S. Carslaw, R. G. Harrison, J. Kirkby", url: "/didattica/4cosmici.pdf" },
            { title: "Fronti freddi: ana, kata e split", url: "/didattica/ColdFronts-2010-RadarCourse-Final2.ppt" },
            { title: "Enhanced Fujita Scale (EF-Scale)", url: "http://www.depts.ttu.edu/nwi/Pubs/FScale/EFScale.pdf" },
            { title: "I fenomeni tornadici nella provincia di Venezia dal 1970 al 2015", url: "/didattica/TORNADOVENETO.pdf" },
            { title: "Sounding-derived parameters associated with severe convective storms in the Netherlands", url: "/didattica/GROENEMEIJER.pdf" },
            { title: "A European lightning density analysis using 5 years of ATDnet data", url: "http://www.nat-hazards-earth-syst-sci.net/14/815/2014/nhess-14-815-2014.pdf" },
            { title: "Guida sull'osservazione (ed interpretazione / spiegazione) dei fenomeni violenti (USA)", url: "http://www.nws.noaa.gov/os/brochures/SGJune6-11.pdf" }
          ]
        },
        {
          name: "Indici temporaleschi",
          description: "Descrizione by Jeff Habby",
          items: [
            { title: "Severe thunderstorm weather", url: "http://www.theweatherprediction.com/severe/" },
            { title: "CAPE",        url: "http://www.theweatherprediction.com/habyhints/305/" },
            { title: "MUCAPE",      url: "http://www.theweatherprediction.com/habyhints2/634/" },
            { title: "CIN",         url: "http://www.theweatherprediction.com/habyhints/306/" },
            { title: "LI",          url: "http://www.theweatherprediction.com/habyhints/300/" },
            { title: "Theta E",     url: "http://www.theweatherprediction.com/habyhints/324/" },
            { title: "Shear",       url: "http://www.theweatherprediction.com/habyhints2/669/" },
            { title: "Shear 0–3 km", url: "http://www.theweatherprediction.com/habyhints/322/" },
            { title: "BRN",         url: "http://www.theweatherprediction.com/habyhints/315/" },
            { title: "SREH",        url: "http://www.theweatherprediction.com/habyhints2/633/" },
            { title: "EHI",         url: "http://www.theweatherprediction.com/habyhints/314/" },
            { title: "SWEAT",       url: "http://www.theweatherprediction.com/habyhints/304/" },
            { title: "Storm motion", url: "http://www.theweatherprediction.com/habyhints/312/" }
          ]
        },
        {
          name: "Meteorologia — Guide",
          items: [
            { title: "Meteorology — Università dell'Illinois", url: "http://ww2010.atmos.uiuc.edu/(Gh)/guides/mtr/home.rxml" },
            { title: "Climate Education — North Carolina State University", url: "http://climate.ncsu.edu/edu/k12/.index" },
            { title: "The Weather Prediction — Jeff Haby", url: "http://www.theweatherprediction.com/" },
            { title: "Atmospheric pressure, winds, and circulation patterns", url: "http://www.cengage.com/resource_uploads/downloads/0495555061_137182.pdf" },
            { title: "The Weather Guide (meteorologia e casi studio relativi alla California)", url: "http://earthguide.ucsd.edu/eoc/teachers/t_climate/pdf/The_Weather_Guide.pdf" },
            { title: "Guida sull'osservazione (ed interpretazione) dei fenomeni violenti (USA)", url: "http://www.nws.noaa.gov/os/brochures/SGJune6-11.pdf" },
            { title: "La micrometeorologia e la dispersione degli inquinanti in aria (R. Sozzi)", url: "http://www.arpat.toscana.it/temi-ambientali/aria/modellistica-per-la-qualita-dellaria/linee-guida/apat-micrometeorologia.pdf" }
          ]
        },
        {
          name: "Casi studio",
          items: [
            { title: "Articolo Meteonetwork — Temporali 25 luglio 2015 (di Francesco De Martin e Giorgio Pavan)", url: "http://www.meteonetwork.it/veneto/25-luglio-2015-supercelle-veneto-nubifragi-friuli" }
          ]
        },
        {
          name: "Ricerca, tesi di laurea — Università di Bologna",
          items: [
            { title: "Analisi meteorologica e modellistica dei due eventi alluvionali in Liguria dell'autunno 2011: Cinque Terre — 25 ottobre, Genova — 4 novembre", url: "http://amslaurea.unibo.it/5908/1/Gallo_Daniele_tesi.pdf" },
            { title: "Struttura nuvolosa del temporale", url: "http://amslaurea.unibo.it/5916/1/santini_davide_tesi.pdf" },
            { title: "Previsione di temporali tramite indici di instabilità ed alberi decisionali", url: "http://amslaurea.unibo.it/7164/1/Bellantone_Paolo_tesi.pdf" }
          ]
        },
        {
          name: "Siti web educativi",
          items: [
            { title: "Fenomeni temporaleschi", url: "http://www.fenomenitemporaleschi.it/" },
            { title: "Eumetcal", url: "http://www.eumetcal.org/courses/" },
            { title: "MetEd", url: "https://www.meted.ucar.edu/" }
          ]
        }
      ]

      section_model = Class.new(ActiveRecord::Base) { self.table_name = "didattica_sections" }
      item_model    = Class.new(ActiveRecord::Base) { self.table_name = "didattica_items" }

      sections.each_with_index do |section, section_index|
        record = section_model.create!(
          name: section[:name],
          description: section[:description],
          position: section_index
        )

        section[:items].each_with_index do |item, item_index|
          item_model.create!(
            didattica_section_id: record.id,
            title: item[:title],
            url: item[:url],
            position: item_index
          )
        end
      end
    end
end
