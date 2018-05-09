require "net/http"
require "uri"
require "json"

module Hitchspots
  # Project OSRM API wrapper
  # Documentation: http://project-osrm.org/docs/v5.10.0/api/
  module Osrm
    # Using Trip service, fetch trip data knowing start and finish locations.
    # doc: http://project-osrm.org/docs/v5.10.0/api/#trip-service
    #
    # @param [Hash] start  Coordidates hash like { lat: 1.23455, lon: 9.87654 }
    # @param [Hash] finist Coordidates hash like { lat: 1.23455, lon: 9.87654 }
    #
    # @return [Hash] A Trip object from OSRM
    def self.trip(places)
      base_url = "https://router.project-osrm.org/trip/v1/driving/"
      places_coords = places.map { |place| "#{place[:lon]},#{place[:lat]}" }.join(";")
      uri = URI("#{base_url}#{places_coords}")

      uri.query = URI.encode_www_form(source: "first",
                                      destination: "last",
                                      roundtrip: false,
                                      geometries: "geojson")

      res = Net::HTTP.get_response(uri)

      raise ApiError, "OSRM unavailable" if res.code != "200"

      JSON.parse(res.body, symbolize_names: true)
    end
  end
end
