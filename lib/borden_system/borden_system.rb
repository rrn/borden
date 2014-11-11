require 'bigdecimal'

module BordenSystem
  ALPHA = "abcdefghijklmnopqrstuvwxyz"

  ALPHA_62 = 'k'

  MINUTES_PER_DEGREE = 60.0

  MAJOR_LAT_DELTA = 2 # degrees
  MINOR_LAT_DELTA = 10 # minutes
  MAJOR_LNG_DELTA = -4 # degrees
  MAJOR_LNG_DELTA_ABOVE_62 = -8 # degrees
  MINOR_LNG_DELTA = -10 # minutes
  MINOR_LNG_DELTA_ABOVE_62 = -20 # minutes

  # Minor offsets to place the mark in the center of the cell designated by the minor index
  MINOR_LAT_UNCERTAINTY = MINOR_LAT_DELTA * 0.5 / MINUTES_PER_DEGREE # degrees
  MINOR_LNG_UNCERTAINTY = MINOR_LNG_DELTA * 0.5 / MINUTES_PER_DEGREE # degrees
  MINOR_LNG_UNCERTAINTY_ABOVE_62 = MINOR_LNG_DELTA_ABOVE_62 * 0.5 / MINUTES_PER_DEGREE # degrees
  MAJOR_LAT_UNCERTAINTY = MAJOR_LAT_DELTA * 0.5 # degrees
  MAJOR_LNG_UNCERTAINTY = MAJOR_LNG_DELTA * 0.5 # degrees
  MAJOR_LNG_UNCERTAINTY_ABOVE_62 = MAJOR_LNG_DELTA_ABOVE_62 * 0.5 # degrees

  BORDEN_SOUTHERN_ORIGIN_LATTITUDE = 42 # degrees
  BORDEN_EASTERN_ORIGIN_LONGITUDE = -52 # degrees
  BORDEN_EASTERN_ORIGIN_LONGITUDE_ABOVE_62 = -48 # degrees

  # AaBb-16:0123 => AaBb
  BORDEN_REGEXP = /\b([A-U])([a-l])?([A-W])([a-x])?\b/
  BORDEN_REGEXP_LOOSE = /([a-uA-U])([a-lA-L])?([a-wA-W])([a-xA-X])?/

  # AaBb-16:0123 => 16
  BORDEN_SITE = /#{BORDEN_REGEXP}-(\d+)/


  # Outputs array of :bounds and the :lat and :lng of the center for the given borden number
  # e,g, "DgRi" => {:bounds => [some bounds], :lat => 'some lat', :lng => 'some long'}
  def self.spatial_components(borden_string)
    if components = number_components(string)
      no62 = north_of_62?(components[:major_north_south])
      output = {:lat => major_south_origin(components[:major_north_south]) + minor_north_offset(components[:minor_north_south]), :lng => major_east_origin(components[:major_east_west], no62) + minor_west_offset(components[:minor_east_west], no62)}

      if components[:minor_north_south] && components[:minor_east_west]
        lng_offset = no62 ? MINOR_LNG_UNCERTAINTY_ABOVE_62 : MINOR_LNG_UNCERTAINTY
        lat_offset = MINOR_LAT_UNCERTAINTY
      else
        lng_offset = no62 ? MAJOR_LNG_UNCERTAINTY_ABOVE_62 : MAJOR_LNG_UNCERTAINTY
        lat_offset = MAJOR_LAT_UNCERTAINTY
      end

      output[:bounds] = [[output[:lat], output[:lng]]]
      output[:bounds] << [output[:lat], output[:lng] + lng_offset * 2]
      output[:bounds] << [output[:lat] + lat_offset * 2, output[:lng] + lng_offset * 2]
      output[:bounds] << [output[:lat] + lat_offset * 2, output[:lng]]

      # Minimize largest uncertainty error by placing the marker in the center of the cell defined by the borden number
      output[:lng] += lng_offset
      output[:lat] += lat_offset

      return output
    end
  end

  # Decompose the borden number into named components
  # e.g. 'DgRs' => :major_north_south => 'D', :minor_north_south => 'g', :major_east_west => 'R', :minor_east_west => 's'
  def self.number_components(string)
    if match = string.match(BORDEN_REGEXP)
      output = {}
      output[:major_north_south] = match[1]
      output[:minor_north_south] = match[2]
      output[:major_east_west] = match[3]
      output[:minor_east_west] = match[4]
      return output
    else
      raise InvalidBordenNumber, "Invalid borden number: #{string}"
    end
  end

  # FIXME: This doesn't always return the correct value because the borden system follows no rules, only guidelines
  def self.borden_number_from_lat_lng(lat, lng)
    offset_lat = BigDecimal.new(lat.to_s) - BORDEN_SOUTHERN_ORIGIN_LATTITUDE
    major_north_south = ALPHA[(offset_lat / MAJOR_LAT_DELTA).floor]
    minor_north_south = ALPHA[offset_lat.modulo(MAJOR_LAT_DELTA) * MINUTES_PER_DEGREE / MINOR_LAT_DELTA]

    if lat > 62
      offset_lng = BigDecimal.new(lng.to_s) - BORDEN_EASTERN_ORIGIN_LONGITUDE_ABOVE_62
      major_east_west = ALPHA[(offset_lng / MAJOR_LNG_DELTA_ABOVE_62).floor * 2]
      minor_east_west = ALPHA[offset_lng.modulo(MAJOR_LNG_DELTA_ABOVE_62) * MINUTES_PER_DEGREE / MINOR_LNG_DELTA_ABOVE_62]
    else
      offset_lng = BigDecimal.new(lng.to_s) - BORDEN_EASTERN_ORIGIN_LONGITUDE
      major_east_west = ALPHA[(offset_lng / MAJOR_LNG_DELTA).floor]
      minor_east_west = ALPHA[offset_lng.modulo(MAJOR_LNG_DELTA) * MINUTES_PER_DEGREE / MINOR_LNG_DELTA]
    end

    return "#{major_north_south.upcase}#{minor_north_south}#{major_east_west.upcase}#{minor_east_west}"
  end

  private

  # Takes The first capital letter of the borden number
  # and returns the lattitude of the southern side of the designated row
  def self.major_south_origin(major_north_south)
    alpha_index_of(major_north_south) * MAJOR_LAT_DELTA + BORDEN_SOUTHERN_ORIGIN_LATTITUDE
  end

  # Takes The first lower case letter of the borden number
  # and returns the within cell northern offset in minutes
  def self.minor_north_offset(minor_north_south)
    alpha_index_of(minor_north_south) * MINOR_LAT_DELTA / MINUTES_PER_DEGREE
  end

  # Takes The second capital letter of the borden number
  # and returns the lattitude of the eastern side of the designated row
  def self.major_east_origin(major_east_west, north_of_62)
    if north_of_62
      alpha_index_of(major_east_west) * MAJOR_LNG_DELTA_ABOVE_62 + BORDEN_EASTERN_ORIGIN_LONGITUDE_ABOVE_62
    else
      alpha_index_of(major_east_west) * MAJOR_LNG_DELTA + BORDEN_EASTERN_ORIGIN_LONGITUDE
    end
  end

  # Takes The second lower case letter of the borden number
  # and returns the within cell western offset in minutes
  def self.minor_west_offset(minor_north_south, north_of_62)
    if north_of_62
      alpha_index_of(minor_north_south) * MINOR_LNG_DELTA_ABOVE_62 / MINUTES_PER_DEGREE
    else
      alpha_index_of(minor_north_south) * MINOR_LNG_DELTA / MINUTES_PER_DEGREE
    end
  end

  # Returns true if the major north south designation is in the region north of 62 degrees where the calculations differ
  def self.north_of_62?(major_north_south)
    major_north_south > ALPHA_62
  end

  def self.alpha_index_of(letter)
    ALPHA.index(letter.to_s.downcase) || 0
  end

  class InvalidBordenNumber < StandardError; end
end
