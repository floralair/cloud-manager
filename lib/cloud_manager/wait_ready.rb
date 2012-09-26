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

# @version 0.5.0

module Serengeti
  module CloudManager

    class Cloud
      def cluster_wait_ready(vm_pool, options = {})
        logger.debug("wait all existed vms poweron and return their ip address")
        group_each_by_threads(vm_pool, :callee=>'wait vm ready') { |vm| vm.wait_ready(options) }
        logger.info("Finish all waiting")
        "finished"
      end
    end
  end
end

