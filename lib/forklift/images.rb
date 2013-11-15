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

require 'forklift/ssh'

module Forklift
  class Images
    include Methadone::CLILogging

    change_logger(Logger.new(STDOUT))

    def self.check_image(image_url, md5sum)
      info "Checking if #{File.basename(image_url)} is already downloaded..."
      debug "Checking if #{File.basename(image_url)} exists on worker."
      require 'open3'
      if Open3.capture3("ssh rightscale@#{Forklift::Config.settings['workers']['ec2']['public_ip']} file /var/cache/forklift/images/#{File.basename(image_url)}")[2].success?
        debug "File, #{File.basename(image_url)} exists on the worker, checking md5sum."
        if Open3.capture3("ssh rightscale@#{Forklift::Config.settings['workers']['ec2']['public_ip']} md5sum /var/cache/forklift/images/#{File.basename(image_url)}")[0].split(' ')[0] == md5sum
          debug "md5sum (#{File.basename(image_url)}) matches."
          return true
        else
          debug "md5sum (#{File.basename(image_url)}) does not match."
          return false
        end
      end
    end

    def self.download_image(image_url)
      info "Downloading #{image_url}..."
      Forklift::Ssh.run_command(Forklift::Config.settings['workers']['ec2']['public_ip'], "cd /var/cache/forklift/images && wget #{image_url}")
    end

    def self.remove_loop_mapper_symlinks
      Forklift::Ssh.run_command(Forklift::Config.settings['workers']['ec2']['public_ip'], "rm /dev/mapper/loop* || true /dev/null 2>&1")
    end
    
    def self.list_images
      Forklift::Ssh.run_command(Forklift::Config.settings['workers']['ec2']['public_ip'], "ls -l /var/cache/forklift/images")
    end

    def self.list_partitions(image_path)
      Forklift::Ssh.run_command("partx -s #{image_path}")
      Forklift::Ssh.run_command("fdisk -l #{image_path}")
    end

    def self.add_partition_mappings(image_path)
      info "Adding partition mappings for #{image_path}..."
      return Forklift::Ssh.return_command(Forklift::Config.settings['workers']['ec2']['public_ip'], "sudo kpartx -av #{image_path}")
    end

    def self.delete_partition_mappings(image_path)
      info "Deleting partition mappings for #{image_path}..."
      Forklift::Ssh.run_command(Forklift::Config.settings['workers']['ec2']['public_ip'], "sudo kpartx -dv #{image_path}")
    end

    def self.mount_mapped_partitions
      Forklift::Ssh.run_command()
    end

    def self.convert(image_path, output_format='raw')
      info "Converting #{image_path} to #{output_format}..."
      Forklift::Ssh.run_command(Forklift::Config.settings['workers']['ec2']['public_ip'], "qemu-img info #{image_path}")
      new_image_path = image_path.gsub('.vmdk', ".#{output_format}")
      Forklift::Ssh.run_command(Forklift::Config.settings['workers']['ec2']['public_ip'], "qemu-img convert -O #{output_format} #{image_path} #{new_image_path} && qemu-img info #{new_image_path} && file #{new_image_path}") 
      return new_image_path
    end

    def self.mount(image_path, part=false)
      debug "Mounting #{image_path}..."
      Forklift::Images::delete_partition_mappings(image_path)
      kpartx_add = Forklift::Images::add_partition_mappings(image_path)
      kpartx_lines = kpartx_add.split(/\r?\n/)
      loop_parts = []
      kpartx_lines.each { |line|
        loop_parts.push(line.split(' ')[2])
      }
      debug "loop partitions detected: #{loop_parts}"

      if part
        puts 'i should just mount the part it wants'
      else
        # mount first only (multiple support is TODO)
        part = loop_parts[0]
        debug "mounting #{part}"
        Forklift::Ssh.run_command(Forklift::Config.settings['workers']['ec2']['public_ip'], "sudo mkdir -p /mnt/#{part} && sudo mount /dev/mapper/#{part} /mnt/#{part}")
      end
    end
  end
end
