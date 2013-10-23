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

module Forklift
  class Ssh
    include Methadone::CLILogging

    change_logger(Logger.new(STDOUT))
    
    def initialize
      debug 'Initializing SSH.'
      system("ssh rightscale@#{ip} 'sudo mkdir -pv /var/cache/forklift/images'")
    end
    
    def self.login(ip)
      system("ssh rightscale@#{ip}")
    end

    def self.run_command(ip, command, r=false, prefix='')
      debug "run cmd: '#{prefix}#{command}' on #{ip}."
      system("ssh -p #{Forklift::Config.settings['ssh']['tunnel']['local_port']} rightscale@127.0.0.1 '#{prefix}#{command}'")
      if $? != 0
        if r == true
          return $?
        else
          raise "Remote command returned non-zero!"
        end
      end
    end

    def self.return_command(ip, command)
      debug "run cmd: '#{command}' on #{ip}."
      result = `ssh -p #{Forklift::Config.settings['ssh']['tunnel']['local_port']} rightscale@127.0.0.1 '#{command}'`
      if $? == 0
        debug "cmd returned: #{result.chomp!}"
        return result
      else
        error "#{result}"
        raise "Remote command returned non-zero!"
      end
    end

    def self.create_tunnel(ip)
      info "Creating SSH tunnel to #{ip}..."
      system("ssh -f -L #{Forklift::Config.settings['ssh']['tunnel']['local_port']}:localhost:22 rightscale@#{ip} sleep 1d")
      system("Sending test command to tunnel...")
      Forklift::Ssh.run_command(Forklift::Config.settings['workers']['ec2']['public_ip'], 'uname -a')
    end
  end
end
