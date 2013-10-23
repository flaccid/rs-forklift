# Author:: Chris Fordham (<chris.fordham@rightcale.com>)
# Copyright:: Copyright (c) 2013 RightScale, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "forklift/version"
require 'yaml'
require 'rest_connection'

module Forklift
  class Config
    include Methadone::CLILogging

    change_logger(Logger.new(STDOUT))
    
    def self.settings
      require 'json'
      config_json = File.join(File.expand_path("~"), ".rightscale", "forklift.json")
      settings = JSON.parse(IO.read(config_json))
      #debug "Settings: #{settings.inspect}"
      return settings
    end
    
    def self.refresh
      debug 'Updating configuration...'
      config_yaml = File.join(File.expand_path("~"), ".rightscale", "forklift.yaml")
      if File.exists?(config_yaml)
        settings = YAML::load(IO.read(config_yaml))
      else
        error "Please create ~/.rightscale/forklift.yaml."
      end
      settings['workers']['ec2']['public_ip'] = Server.find(settings['workers']['ec2']['server_id']).settings['ip-address']
      require 'json'
      IO.write(File.join(File.expand_path("~"), ".rightscale", "forklift.json"), JSON.pretty_generate(settings))
    end
  end
end
