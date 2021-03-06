#
# Copyright 2011 Red Hat, Inc.
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
#

module Backstage
  class Message
    include Resource

    IGNORED_PROPERTIES = [ 'JMSXDeliveryCount', TorqueBox::Messaging::Message::ENCODING_PROPERTY ]
    
    def initialize(message)
      @torquebox_message = message
    end

    def jms_message
      @torquebox_message.jms_message
    end

    def content
      @torquebox_message.decode.inspect
    rescue Exception => ex
      if @jms_message.respond_to?(:text)
        @jms_message.text 
      else
        "Undecodable message"
      end
    end

    def jms_id
      jms_message.jms_message_id
    end
    alias_method :full_name, :jms_id
    
    def properties
      @properties ||= jms_message.property_names.inject( {} ) do |properties, name|
        properties[name] = jms_message.get_string_property( name ) unless IGNORED_PROPERTIES.include?( name )
        properties        
      end
    end
    
    JMS_PROPERTIES = %w{ JMS_Correlation_ID JMS_Priority JMS_Type JMS_Reply_To JMS_Redelivered }
    def jms_properties
      @jms_properties ||= JMS_PROPERTIES.inject( {} ) do |props,name|
        value = jms_message.send(name.downcase)
        props[name.gsub('_',' ')] = value.to_s if value # Ignore empty values
        props
      end
    end

    def delivery_count
      jms_message.get_string_property( 'JMSXDeliveryCount' )
    end

    def self.to_hash_attributes
      super + [:jms_id, :delivery_count, :properties, :content]
    end
  end
end
