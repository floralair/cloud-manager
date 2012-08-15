###############################################################################
#   Copyright (c) 2012 VMware, Inc. All Rights Reserved.
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
################################################################################

# @since serengeti 0.5.0
# @version 0.5.0


require 'cloud_manager/config'
require 'cloud_manager/exception'
require 'cloud_manager/utils'
require 'cloud_manager/log'
require 'cloud_manager/resource_service'
require 'cloud_manager/placement_service'
require 'cloud_manager/network_res'
require 'cloud_manager/vm'
require 'cloud_manager/resources'
require 'cloud_manager/group'
require 'cloud_manager/vm_group'
require 'cloud_manager/placement'
require 'cloud_manager/placement_impl'
require 'cloud_manager/virtual_node'
require 'cloud_manager/wait_ready'
require 'cloud_manager/deploy'
require 'cloud_manager/cloud_deploy'
require 'cloud_manager/iaas_progress'
require 'cloud_manager/iaas_result'
require 'cloud_manager/iaas_task'
require 'cloud_manager/cloud_progress'
require 'cloud_manager/cloud_create'
require 'cloud_manager/cloud_operations'
require 'cloud_manager/cloud'
require 'cloud_manager/cluster'

module Serengeti
  module CloudManager
    class Manager
      def self.read_provider_from_file(parameter)
        cloud_path = ENV["CLOUD_MANAGER_CONFIG_DIR"] || '/opt/serengeti/conf'
        puts("read #{cloud_path }.")
        provider_file = "#{cloud_path}/cloud-manager.#{parameter['cloud_provider']['name']}.yaml"
        begin
          provider_config = YAML.load(File.open(provider_file))
          parameter['cloud_provider']['vc_addr'] = provider_config['vc_addr']
          parameter['cloud_provider']['vc_user'] = provider_config['vc_user']
          parameter['cloud_provider']['vc_pwd']  = provider_config['vc_pwd']
        rescue => e
          puts("fail to read #{provider_file}. It will read config from parameter 'cloud_provider'")
        end
      end

      def self.cluster_helper(parameter, options={})
        cloud = nil
        begin
          #Handle cloud_provider
          read_provider_from_file(parameter)
          cloud = IaasTask.new(parameter['cluster_definition'],
                               parameter['cloud_provider'],
                               parameter['cluster_data'],
                               parameter['targets'])
          if (options[:wait])
            begin
              yield cloud
            ensure
              cloud.release_connection if cloud
            end
          else
            # options["sync"] == false
            Thread.new do
              begin
                yield cloud
              ensure
                cloud.release_connection if cloud
              end
            end
          end
        end
        cloud
      end

      def self.start_cluster(parameter, options={})
        cluster_helper(parameter, options) { |cloud| cloud.start }
      end

      def self.stop_cluster(parameter, options={})
        cluster_helper(parameter, options) { |cloud| cloud.stop }
      end

      def self.delete_cluster(parameter, options={})
        cluster_helper(parameter, options) { |cloud| cloud.delete }
      end

      def self.create_cluster(parameter, options={})
        cluster_helper(parameter, options) { |cloud| cloud.create_and_update }
      end

      # TODO change to show_cluster
      def self.list_vms_cluster(parameter, options={})
        cloud = nil
        begin
          read_provider_from_file(parameter)
          cloud = IaasTask.new(parameter['cluster_definition'], parameter['cloud_provider'], parameter['cluster_data'], parameter['targets'])
          return cloud.list_vms
        ensure
          cloud.release_connection if cloud
        end
      end

      def self.set_log_level(level)
        Serengeti::CloudManager.set_log_level(level)
      end
    end
  end
end
