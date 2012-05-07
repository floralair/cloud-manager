module VHelper::CloudManager
  class VHelperCloud
    CLUSTER_ACTION_MESSAGE = {
      CLUSTER_DELETE => 'delete',
      CLUSTER_START  => 'start',
      CLUSTER_STOP   => 'stop',
    }

    def vhelper_vm_op(cloud_provider, cluster_info, task, action)
      act = CLUSTER_ACTION_MESSAGE[action]
      act = 'unknown' if act.nil?
      @logger.debug("enter #{act} cluster ... ")
      create_cloud_provider(cloud_provider)
      dc_resources, vm_groups_existed, vm_groups_input = prepare_working(cluster_info)

      @status = action 
      matched_vms = []
      dc_resources.clusters.each_value { |cluster|
        matched_vm = cluster.vms.values.select{|vm| vm_is_this_cluster?(vm.name)}
        matched_vms << matched_vm unless matched_vm.empty? 
      }
      matched_vms.flatten!

      #@logger.debug("#{matched_vms.pretty_inspect}")
      @logger.debug("vms name: #{matched_vms.collect{|vm| vm.name}.pretty_inspect}")
      yield matched_vms
      @status = CLUSTER_DONE
      cluster_done(task)

      @logger.debug("#{act} all vm's")
    end

    def delete(cloud_provider, cluster_info, task)
      action_process (CLOUD_WORK_DELETE) {
        vhelper_vm_op(cloud_provider, cluster_info, task, CLUSTER_DELETE) {|vms|
          group_each_by_threads(vms) { |vm|
            #@logger.debug("Can we delete #{vm.name} same as #{cluster_info["name"]}?")
            #@logger.debug("vm split to #{@cluster_name}::#{result[2]}::#{result[3]}")
            @logger.debug("delete vm : #{vm.name}")
            next if !vm_deploy_op(vm, 'delete') { @client.vm_destroy(vm) }
          }
        }
      }
    end

    def start(cloud_provider, cluster_info, task)
      action_process(CLOUD_WORK_START) {
        vhelper_vm_op(cloud_provider, cluster_info, task, CLUSTER_START) {|vms|
          cluster_wait_ready(vms)
        }
      }
    end

    def stop(cloud_provider, cluster_info, task)
      action_process(CLOUD_WORK_STOP) {
        vhelper_vm_op(cloud_provider, cluster_info, task, CLUSTER_STOP) { |vms|
          group_each_by_threads(vms) { |vm|
            @logger.debug("stop :#{vm.name}")

            next if !vm_deploy_op(vm, 'stop') { @client.vm_power_off(vm) }
          }
        }
      }
    end

  end
end
