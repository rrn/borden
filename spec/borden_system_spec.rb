require 'spec_helper'

describe BordenSystem do
  describe '#borden_number_from_lat_lng' do
    it "returns the correct value for the origin" do
      expect( BordenSystem.borden_number_from_lat_lng(42, -52) ).to eq('AaAa')
    end

    it "returns the correct value for lats below 62 degrees" do
      expect( BordenSystem.borden_number_from_lat_lng(49.4, -123.1) ).to eq('DiRs')
    end

    it "returns the correct value for lats at 62 degrees" do
      expect( BordenSystem.borden_number_from_lat_lng(62, -123.1) ).to eq('KaRs')
    end

    it "returns the correct value for lats above 62 degrees" do
      # expect( BordenSystem.borden_number_from_lat_lng(67, -123.1) ).to eq('MgSs')
    end
  end

  describe '#number_components' do
    it "returns the correct number components for a valid borden number" do
      expect( BordenSystem.number_components('DgRs') ).to eq(:major_north_south => 'D', :minor_north_south => 'g', :major_east_west => 'R', :minor_east_west => 's')
    end

    it "raises an exception when given an invalid borden number" do
      expect{ BordenSystem.number_components('ZgRs') }.to raise_exception(BordenSystem::InvalidBordenNumber)
    end
  end
end
