class PagesController < ApplicationController
  def guida_alle_previsioni
  end

  def monitoraggio_radar
    @radars = RadarMonitoring.ordered
  end

  def monitoraggio_fulmini
  end

  def monitoraggio_satelliti
  end

  def monitoraggio_stazione_meteo
  end

  def monitoraggio_radiosondaggi
  end
end
