module DB
  # Interract with db[:spots] collection through this class
  # Incoming data comes from Hitchwiki API, it is saved in a db
  # document with this content:
  #
  # _id       BSON::ObjectId autogenerated by mongo db
  # raw       Hash           parsed JSON, raw data from hitchwiki
  # sanitized Hash           sanitized data for hitchspots
  #
  # returned value should be ignored
  class Spot
    Collection = Sinatra::Application.settings.mongo_db

    # Fetch all spots in Database
    #
    # @return [Array] A collection of detailed spots
    def self.all
      Collection.find.to_a
    end

    attr_reader :id, :raw

    def initialize(id:, **params)
      @id = id
      @raw = { id: @id }.merge(params)
    end

    def data
      { raw: raw, sanitized: sanitize(raw) }
    end

    def data_without_re_encoding
      { raw: raw, sanitized: sanitize(raw, fix_encoding: false) }
    end

    def save
      if Collection.find("raw.id" => id).to_a.empty?
        insert
      else
        update
      end
    end

    def insert
      Collection.insert_one data
    rescue ArgumentError
      Collection.insert_one data_without_re_encoding
    end

    def update
      Collection.find_one_and_update({ "raw.id" => id },
                                     { "$set" => data },
                                     return_document: :after)
    rescue ArgumentError
      Collection.find_one_and_update({ "raw.id" => id },
                                     { "$set" => data_without_re_encoding },
                                     return_document: :after)
    end

    def destroy
      Collection.find_one_and_delete("raw.id" => id)
    end

    private

    # rubocop:disable Metrics/MethodLength
    def sanitize(params, fix_encoding: true)
      Hash[
        params.map do |key, value|
          next [key, value.to_f] if [:lat, :lon].include? key

          # next unless == continue if
          next [key, value] unless fix_encoding

          new_value = case value
                      when String then re_encode(value)
                      when Array  then value.map { |v| sanitize(v) }
                      when Hash   then sanitize(value)
                      else             value
                      end

          [key, new_value]
        end
      ]
    end
    # rubocop:enable Metrics/MethodLength

    def re_encode(string)
      string.encode("Windows-1252").force_encoding("utf-8")
    rescue Encoding::UndefinedConversionError
      nil
    end
  end
end
