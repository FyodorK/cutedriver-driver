############################################################################
## 
## Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies). 
## All rights reserved. 
## Contact: Nokia Corporation (testabilitydriver@nokia.com) 
## 
## This file is part of Testability Driver. 
## 
## If you have questions regarding the use of this file, please contact 
## Nokia at testabilitydriver@nokia.com . 
## 
## This library is free software; you can redistribute it and/or 
## modify it under the terms of the GNU Lesser General Public 
## License version 2.1 as published by the Free Software Foundation 
## and appearing in the file LICENSE.LGPL included in the packaging 
## of this file. 
## 
############################################################################


# verify that plugin engine and modules is loaded
Kernel::raise RuntimeError.new( "SUT plugin requires TDriver" ) unless defined?( MobyUtil::Plugin )

module MobyPlugin

	module Generic

		class SUT < MobyUtil::Plugin

			## plugin configuration, constructor and deconstructor methods
			def self.plugin_name

				# return plugin name as string
				"tdriver-generic-sut-plugin"
			end

			def self.plugin_type

				# return plugin type as symbol
				:sut

			end

			def self.register_plugin

				# load plugin specific implementation or other initialization etc.
				MobyUtil::FileHelper.load_modules( 

					# load behaviour(s)
					'behaviours/*.rb',

					# load commands(s)
					'commands/*.rb'

				)

			end

			def self.unregister_plugin

				# unregister plugin

			end

			## plugin specific methods

			# return sut type that plugin implements
			def self.sut_type

				# return sut type as string
				"generic"

			end

			# returns SUT object - this method will be called from MobyBase::SUTFactory
			def self.make_sut( sut_id )

				MobyBase::SUT.new( 
					MobyBase::SutController.new( "", MobyController::SutAdapter.new() ), 
					MobyBase::TestObjectFactory.instance,
					sut_id
				)

			end

			# enable hooking for performance measurement & debug logging
			MobyUtil::Hooking.instance.hook_methods( self ) if defined?( MobyUtil::Hooking )

			# register plugin
			MobyUtil::PluginService.instance.register_plugin( self ) # Note: self is MobyPlugin::Generic::SUT

		end # SUT

	end # Generic

end # MobyPlugin
