#!/usr/bin/env ruby
# -------------------------------------------------------------------------- */
# Copyright 2002-2009, Distributed Systems Architecture Group, Universidad   */
# Complutense de Madrid (dsa-research.org)                                   */
# Licensed under the Apache License, Version 2.0 (the "License"); you may    */
# not use this file except in compliance with the License. You may obtain    */
# a copy of the License at                                                   */
#                                                                            */
# http://www.apache.org/licenses/LICENSE-2.0                                 */
#                                                                            */
# Unless required by applicable law or agreed to in writing, software        */
# distributed under the License is distributed on an "AS IS" BASIS,          */
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   */
# See the License for the specific language governing permissions and        */
# limitations under the License.                                             */
# -------------------------------------------------------------------------- */

ONE_LOCATION = ENV["ONE_LOCATION"]

if !ONE_LOCATION
    RUBY_LIB_LOCATION = "/usr/lib/one/ruby"
    ETC_LOCATION      = "/etc/one/"
else
    RUBY_LIB_LOCATION = ONE_LOCATION + "/lib/ruby"
    ETC_LOCATION      = ONE_LOCATION + "/etc/"
end
CONFIG_FILE_LOCATION = ETC_LOCATION + "one_dummy.conf" 

$: << RUBY_LIB_LOCATION
require "yaml"
require "rubygems"
require "nokogiri"
require "VirtualMachineDriver"
require "CommandManager"

class DummyDriver < VirtualMachineDriver
    ######################################
    #
    # Init default configuration
    #
    ######################################
    ACTIONS_CONFIG = {
        :save => "SUSPEND",
        :restore => "RESTORE",
        :shutdown => "SHUTDOWN",
        :deploy => "DEPLOY",
        :cancel => "CANCEL",
        :restore => "RESTORE",
        :migrate => "MIGRATE",
        :poll => "POLL"
    }
    DEFAULT_CONFIG = {
        "SUSPEND" => 'normal',
        "SUSPEND-WAIT" => 0,
        "SHUTDOWN" => 'normal',
        "SHUTDOWN-WAIT" => 0,
        "DEPLOY" => 'normal',
        "DEPLOY-WAIT" => 0,
        "CANCEL" => 'normal',
        "CANCEL-WAIT" => 0,
        "RESTORE" => 'normal',
        "RESTORE-WAIT" => 0,
        "MIGRATE" => 'normal',
        "MIGRATE-WAIT" => 0
    
    }
    def initialize
        super(15,false)
        @vmm_config = {}
        @file_config = YAML::load(File.read(CONFIG_FILE_LOCATION))

    end

    def deploy(id, host, remote_dfile, not_used)
        init_config(id,remote_dfile)
        do_config(id,:deploy,remote_dfile)
    end

    def shutdown(id, host, deploy_id, not_used)
        do_config(id,:shutdown)
    end

    def cancel(id, host, deploy_id, not_used)
        resul = do_config(id,:cancel)
    end

    def save(id, host, deploy_id, file)
       # send_message('LOG','At the moment no problem')
       # suspend = @vmm_config[id].xpath('//SUSPEND')
       # send_message('LOG','ummm',suspend.length)
       # if suspend.length >= 1:
       #     send_message('A las barricadas, no pasaran')
       #     if @vmm_config[id].xpath('//SUSPEND')[0].content == 'sleep'
       #         send_message('LOG','SLEEPING',id,host)
       #         sleep(Integer(@vmm_config[id].xpath('//SUSPEND_SLEEP')[0].content))
       #     end
       # end
        do_config(id,:save)
    end

    def restore(id, host, deploy_id , file)
        do_config(id,:restore)
    end

    def migrate(id, host, deploy_id, dest_host)
        do_config(id,:migrate)
    end

    def poll(id, host, deploy_id, not_used)
        # monitor_info: string in the form "VAR=VAL VAR=VAL ... VAR=VAL"
        # known VAR are in POLL_ATTRIBUTES. VM states VM_STATES
        monitor_info = "#{POLL_ATTRIBUTE[:state]}=#{VM_STATE[:active]} " \
                       "#{POLL_ATTRIBUTE[:nettx]}=12345"

        send_message(ACTION[:poll],RESULT[:success],id,monitor_info)
    end
    ###################################################
    # Config part
    ###################################################
    def init_config(id, remote_dfile)
        send_message(ACTION[:log],'Init config for '+id.to_s,remote_dfile)
        divided = remote_dfile.split('/images')
        file = divided[0]+divided[1]
        f = File.open(file)
        config = Nokogiri::XML(f).xpath('//DUMMY')
        send_message(ACTION[:log],'Finished reading config file for '+id.to_s)
        # send_message(@vmm_config[id].xpath('//SUSPEND')[0].content )
        if config == nil
            @vmm_config[id] = Hash.new
        else
            @vmm_config[id] = config
        end
    end
    def do_config(id, caction,arg = nil)
        wtd = get_config(id,ACTIONS_CONFIG[caction]).downcase
        send_message(ACTION[:log],'Checking what to do for this action', caction)
        if wtd == 'sleep' or wtd == 'fail'
            if Integer(get_config(id,ACTIONS_CONFIG[caction]+'_WAIT')) > 0
                sleep(Integer(get_config(id,ACTIONS_CONFIG[caction]+'_WAIT')))
            end
        end
        if wtd == 'normal' or wtd == 'sleep'
            send_message(ACTION[caction],RESULT[:success],id,arg)
        else
            send_message(ACTION[caction],RESULT[:failure],id)
        end
    end
    def get_config(id, gaction)
        send_message(ACTION[:log],'Getting configuration for '+gaction.upcase)
        send_message(ACTION[:log], 'This option does not exits') unless DEFAULT_CONFIG[gaction.upcase] != nil
        # Default Config is NORMAL for all cases
        # Actual accpeted settings: Sleep, Fail, Normal or numerical 
        vmC = @vmm_config[id].xpath('//'+gaction.upcase)
        send_message(ACTION[:log],'VMC ',vmC)
        vmF = @file_config['vmm'][gaction.upcase] unless @file_config['vmm'] == nil
        
        if vmC.length > 0
            gettedC =  vmC[0].content
        elsif vmF != nil
            gettedC = vmF
        else
            gettedC = DEFAULT_CONFIG[gaction.upcase]
        end
        send_message(ACTION[:log],'Config getted for '+gaction.upcase,'is '+gettedC.to_s)
        return gettedC

        

    end
end

dd = DummyDriver.new
dd.start_driver
