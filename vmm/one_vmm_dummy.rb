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

$: << RUBY_LIB_LOCATION
require "rubygems"
require "nokogiri"
require "VirtualMachineDriver"
require "CommandManager"

class DummyDriver < VirtualMachineDriver
    def initialize
        super(15,true)
        @vmm_config = {}
    end

    def deploy(id, host, remote_dfile, not_used)
        get_config(id,remote_dfile)
        send_message(ACTION[:deploy],RESULT[:success],id,remote_dfile)
    end

    def shutdown(id, host, deploy_id, not_used)
        send_message(ACTION[:shutdown],RESULT[:success],id)
    end

    def cancel(id, host, deploy_id, not_used)
        send_message(ACTION[:cancel],RESULT[:success],id)
    end

    def save(id, host, deploy_id, file)
        if @vmm_config[id].xpath('//SUSPEND')[0].content == 'sleep'
            send_message('LOG','SLEEPING ...')
            sleep(Integer(@vmm_config[id].xpath('//SUSPEND_SLEEP')[0].content))
        end
        send_message(ACTION[:save],RESULT[:success],id)
    end

    def restore(id, host, deploy_id , file)
        send_message(ACTION[:restore],RESULT[:success],id)
    end

    def migrate(id, host, deploy_id, dest_host)
        send_message(ACTION[:migrate],RESULT[:success],id)
    end

    def poll(id, host, deploy_id, not_used)
        # monitor_info: string in the form "VAR=VAL VAR=VAL ... VAR=VAL"
        # known VAR are in POLL_ATTRIBUTES. VM states VM_STATES
        monitor_info = "#{POLL_ATTRIBUTE[:state]}=#{VM_STATE[:active]} " \
                       "#{POLL_ATTRIBUTE[:nettx]}=12345"

        send_message(ACTION[:poll],RESULT[:success],id,monitor_info)
    end

    def get_config(id, remote_dfile)
        divided = remote_dfile.split('/images')
        file = divided[0]+divided[1]
        f = File.open(file)
        config = Nokogiri::XML(f).xpath('//DUMMY')
       # send_message(@vmm_config[id].xpath('//SUSPEND')[0].content )
        @vmm_config[id] = config
        

    end
end

dd = DummyDriver.new
dd.start_driver
