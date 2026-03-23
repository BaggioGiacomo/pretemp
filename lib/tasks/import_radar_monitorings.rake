namespace :import do
  desc "Import radar monitoring entries"
  task radar_monitorings: :environment do
    items = [
      { name: "MAPPA NAZIONALE DPC", url: "https://mappe.protezionecivile.gov.it/it/mappe-rischi/piattaforma-radar" },
      { name: "Friuli Venezia Giulia (OSMER-PC)", url: "http://www.osmer.fvg.it/radar.php?ln=&m=0" },
      { name: "Veneto (ARPAV)", url: "http://www.arpa.veneto.it/bollettini/meteo/radar/radar.php" },
      { name: "Trentino Alto Adige (Meteotrentino)", url: "https://www.meteotrentino.it/?ID=144#!/content?menuItemDesktop=26" },
      { name: "Valle d'Aosta, Piemonte, Liguria (ARPA Piemonte)", url: "https://www.arpa.piemonte.it/rischi_naturali/snippets_arpa_alpine/radar/" },
      { name: "Emilia Romagna (ARPAE)", url: "https://www.arpae.it/it/temi-ambientali/meteo/dati-e-osservazioni/stima-radar-della-pioggia" },
      { name: "Lombardia (MeteoSwiss)", url: "http://www.centrometeolombardo.com/radar/" },
      { name: "Toscana e Liguria (LAMMA)", url: "https://www.lamma.toscana.it/meteo/osservazioni-e-dati/radar" },
      { name: "Slovenia (ARSO)", url: "http://www.meteo.si/uploads/meteo/app/inca/?par=si0zm&lang=en" },
      { name: "Svizzera", url: "http://www.meteocentrale.ch/it/meteo/radar.html" },
      { name: "Centro Italia Tortoreto", url: "http://cfa.aquila.infn.it/osservazioni/radarmeteo/tortoreto.html" },
      { name: "Centro Italia Tufillo", url: "http://radarweb.aquila.infn.it/tufillo/" },
      { name: "Centro Italia Monte Midia", url: "http://satollo.aquila.infn.it/midia/ref/" },
      { name: "Centro Italia L'Aquila", url: "http://radarweb.aquila.infn.it/wr25xp/" },
      { name: "Composito centro Italia", url: "http://cfa.aquila.infn.it/osservazioni/radarmeteo/composito-regionale.html" },
      { name: "Campania (CARMEN)", url: "https://www.radarmeteo.uniparthenope.it/index.html" },
      { name: "Sardegna (ARPAS)", url: "http://www.sar.sardegna.it/servizi/meteo/imgradar_it.asp" },
      { name: "RADAR PREVISIONALE ZAMG - AUSTRIA", url: "http://www.zamg.ac.at/cms/de/wetter/wetteranimation" },
      { name: "RADAR LANDI - PREVISIONE PROSSIME 24H (Provincia Autonoma Di Bolzano)", url: "http://meteo.provincia.bz.it/previsione-precipitazione.asp" }
    ]

    total = items.size

    items.each_with_index do |item, index|
      priority = total - 1 - index

      record = RadarMonitoring.find_or_initialize_by(name: item[:name])
      record.url = item[:url]
      record.priority = priority
      record.save!

      puts "#{record.persisted? ? 'Saved' : 'Created'}: #{item[:name]} (priority: #{priority})"
    end

    puts "\nDone! Imported #{total} radar monitoring entries."
  end
end
