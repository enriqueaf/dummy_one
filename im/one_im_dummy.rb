#!/usr/bin/env ruby

# -------------------------------------------------------------------------- #
# Copyright 2002-2009, Distributed Systems Architecture Group, Universidad   #
# Complutense de Madrid (dsa-research.org)                                   #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

ONE_LOCATION=ENV["ONE_LOCATION"]

if !ONE_LOCATION
    RUBY_LIB_LOCATION="/usr/lib/one/ruby"
    ETC_LOCATION="/etc/one/"
else
    RUBY_LIB_LOCATION=ONE_LOCATION+"/lib/ruby"
    ETC_LOCATION=ONE_LOCATION+"/etc/"
end

CONFIG_FILE = ETC_LOCATION + "one_im_dummy.rb"

$: << RUBY_LIB_LOCATION

require 'yaml'
require 'OpenNebulaDriver'
require 'CommandManager'

#-------------------------------------------------------------------------------
# The SSH Information Manager Driver
#-------------------------------------------------------------------------------
class DummyInformationManager < OpenNebulaDriver

    #---------------------------------------------------------------------------
    # Init the driver
    #---------------------------------------------------------------------------
    def initialize(num)
        super(num, true)
        # register actions
        register_action(:MONITOR, method("action_monitor"))
    end

    #---------------------------------------------------------------------------
    # Execute the sensor array in the remote host
    #---------------------------------------------------------------------------
    def action_monitor(number, host)
        config = get_configuration(host)
        results =  "HYPERVISOR=dummy,"
        results << "NAME=#{host},"

        results << "TOTALCPU=#{config['CPU']},"
        results << "CPUSPEED=2.2GHz,"

        results << "TOTALMEMORY=16777216,"
        results << "USEDMEMORY=0,"
        results << "FREEMEMORY=16777216,"

        results << "FREECPU=#{config['FREECPU']},"
        results << "USEDCPU=0"

        send_message("MONITOR", RESULT[:success], number, results)
    end
    
    #-------------------------------------------------------------------------------
    # Getting the config file
    # Files are readed in RealTime, wich mean that you can modify files, whenever you want, but be carefull.
    #-------------------------------------------------------------------------------

    def get_configuration(host)
        config = YAML::load(File.read(CONFIG_FILE))
        return config[host]
    end

end

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# Information Manager main program
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

im = DummyInformationManager.new(15)
im.start_driver
