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
require "forklift/config"
require "forklift/ssh"

require "rest_connection"

module Forklift
  class Workers
    include Methadone::CLILogging
    
    change_logger(Logger.new(STDOUT))

    def self.list()
      info "Querying RightScale for Forklift workers..."
      workers = Tag.search('Ec2Instance', ["forklift:worker=ec2"]).uniq { |worker| worker['href'] }
      if workers.count
        info "Total workers found: #{workers.count}"
        workers.each do |worker|
          info "Retrieving server settings for #{worker['href']}"
          server = Server.find(worker['href'])
          info "------------------------------------------------"
          info "#{server.settings['nickname']} (#{server.settings['ip_address']})"
          debug server.settings.to_yaml
          info "------------------------------------------------"
        end
      else
        error "No Forklift workers found."
      end
    end

    def self.test()
      info "Testing Forklift workers..."
      path_commands = [ 'qemu-img', 'wget', 'unzip', 'md5sum', 'mkdir', 'grep', 'kpartx' ]
      path_commands.each do |cmd|
        debug "Checking for #{cmd}..."
        Forklift::Ssh.run_command(Forklift::Config.settings['workers']['ec2']['public_ip'], "which #{cmd}")
      end
    end
  end
end
