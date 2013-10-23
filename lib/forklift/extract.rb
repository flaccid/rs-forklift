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

module Forklift
  class Extract
    include Methadone::CLILogging

    change_logger(Logger.new(STDOUT))
    
    def self.zip(filepath)
      info "Extracting #{filepath}..."
      Forklift::Ssh.run_command(Forklift::Config.settings['workers']['ec2']['public_ip'], "sudo mkdir -p /var/cache/forklift/extracted/#{File.basename(filepath)} && sudo unzip -u /var/cache/forklift/images/#{File.basename(filepath)} -d /var/cache/forklift/extracted/#{File.basename(filepath)}")
    end
  end
end
