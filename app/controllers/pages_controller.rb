class PagesController < ApplicationController
  def guida_alle_previsioni
  end

  def obiettivi_e_struttura
  end

  def team
    @users = User.all.order(:created_at)
  end

  def monitoraggio_radar
    @radar_monitorings = RadarMonitoring.ordered
  end

  def monitoraggio_fulmini
    @lightning_monitorings = LightningMonitoring.ordered
  end

  def monitoraggio_satelliti
    @satellite_monitorings = SatelliteMonitoring.ordered
  end

  def monitoraggio_stazioni_meteo
    @weather_station_monitorings = WeatherStationMonitoring.ordered
  end

  def monitoraggio_radiosondaggi
    @radio_poll_monitorings = RadioPollMonitoring.ordered
  end

  def progetto_storm_report
  end

  def guida_storm_report
  end

  def contatti
  end

  def pubblicazioni_scientifiche
  end

  def report_tecnici
  end
end
