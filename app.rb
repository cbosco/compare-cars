#app.rb

require "sinatra"
require "erb"
require 'curb'
require 'json'

# https://gist.github.com/oisin/987247
# Set the version of the API being run here
#
MAJOR_VERSION = 1
MINOR_VERSION = 0
VERSION_REGEX = %r{/api/v(\d)\.(\d)}

BODY_TYPE_KEY = {
    'Sedan' => 'sedan',
    'Hatchback' => 'hatch',
    'Van' => 'van',
    'Coupe' => 'coupe',
    'Sport Utility' => 'suv',
    'Truck' => 'truck'
}
helpers do
    def version_compatible?(nums)
        return MAJOR_VERSION == nums[0].to_i && MINOR_VERSION >= nums[1].to_i
    end
end

# Enforce compatibility before the call. Rewrite the
# URL in the request to remove the API versioning stuff
#
before VERSION_REGEX do
    if version_compatible?(params[:captures])
        request.path_info = request.path_info.match(VERSION_REGEX).post_match
    else
        halt 400, "Version not compatible with this server"
    end
end

def json_parse_autotrader_response(response)
    begin
        response_array = response.split('[')[1]
        response_array = response_array.split(']')[0]
        "[#{response_array}]"
    rescue
        [].to_json
    end
end

before do
    content_type 'application/json'
end

get "/makes" do
    unless params[:developerMode]
        http = Curl.post("http://www.autotrader.com/dwr/call/plaincall/ModelSearchUtil.getAllMakes.dwr", {
            'callCount' => '1',
            'scriptSessionId' => '',
            'c0-scriptName' => 'ModelSearchUtil',
            'c0-methodName' => 'getAllMakes',
            'batchId' => '1'
        })
        resp = http.body_str
    else
        resp = File.read(File.join('samples', 'makes.json'))
    end
    json_parse_autotrader_response resp
end

get "/models" do
    unless params[:developerMode]
        http = Curl.post("http://www.autotrader.com/dwr/call/plaincall/ModelSearchUtil.getAllRetailModels.dwr", {
            'callCount' => '1',
            'scriptSessionId' => '',
            'c0-scriptName' => 'ModelSearchUtil',
            'c0-methodName' => 'getAllRetailModels',
            'c0-param0' => "string:#{params[:make]}",
        })
        resp = http.body_str
    else
        # Chevrolet
        resp = File.read(File.join('samples', 'models.json'))
    end
    json_parse_autotrader_response resp
end

get "/years" do
    unless params[:developerMode]
        http = Curl.post("http://www.autotrader.com/dwr/call/plaincall/ModelSearchUtil.getRetailYearsByMakeModel.dwr", {
            'callCount' => '1',
            'scriptSessionId' => '',
            'c0-scriptName' => 'ModelSearchUtil',
            'c0-methodName' => 'getRetailYearsByMakeModel',
            'c0-param0' => "string:#{params[:make]}",
            'c0-param1' => "string:#{params[:model]}"
        })
        resp = http.body_str
    else
        # Chevrolet Corvette
        resp = File.read(File.join('samples', 'years.json'))
    end
    json_parse_autotrader_response resp
end

# name, value pairs
get "/trims" do
    unless params[:developerMode]
        http = Curl::Easy.perform("http://www.autotrader.com/ac-servlets/research/compare/ctr/getCars?column=1&cars=year:#{params[:year]}|make:#{params[:make]}|model:#{params[:model]}")
        resp = http.body_str
    else
        # 2012 Chevrolet Corvette
        resp = File.read(File.join('samples', 'trims.json'))
    end
    begin
        resp = JSON.parse resp
        resp['cars'][0]['ctr']['trims'].to_json
    rescue
        [].to_json
    end
end

get "/car" do
    unless params[:developerMode]
        http = Curl::Easy.perform("http://www.autotrader.com/ac-servlets/research/compare/ctr/getCars?column=1&cars=year:#{params[:year]}|make:#{params[:make]}|model:#{params[:model]}|styleId:#{params[:styleId]}")
        resp = http.body_str
    else
        # 2012 Chevrolet Corvette 2dr Cpe w/1LT (#332287)
        resp = File.read(File.join('samples', 'car.json'))
    end
    begin
        resp = JSON.parse resp
        car_raw = resp['cars'][0]['ctr']

        car = {}
        car['msrp'] = car_raw['cost']['msrp'].delete "$"

        car['hp'] = car_raw['featureMap']['fm_SAE_Net_Horsepower___RPM'].to_i
        car['torque'] = car_raw['featureMap']['fm_SAE_Net_Torque___RPM'].to_i

        # manual / auto details
        # some cars say zero :(
        car['mpgc'] = car_raw['featureMap']['fm_EPA_MANUAL_CITY']
        car['mpgh'] = car_raw['featureMap']['fm_EPA_MANUAL_HIGHWAY']

        car['mpgc'] = car_raw['mileageCITY'].to_i
        car['mpgh'] = car_raw['mileageHWY'].to_i

        car['fuel'] = car_raw['featureMap']['fm_Fuel_Tank_Capacity__Approx__gal_']
        car['weight'] = car_raw['featureMap']['fm_Base_Curb_Weight__lbs_']
        # often missing :(
        car['length'] = car_raw['featureMap']['fm_Length__Overall_w_o_rear_bumper__in_'].to_i
        car['wheelbase'] = car_raw['featureMap']['fm_Wheelbase__in_']
        car['width'] = car_raw['featureMap']['fm_Width__Max_w_o_mirrors__in_']
        car['height'] = car_raw['featureMap']['fm_Height__Overall__in_']

        car['body'] = BODY_TYPE_KEY[car_raw['vehicleType']]

        car.to_json
    rescue
        {}.to_json
    end
end

