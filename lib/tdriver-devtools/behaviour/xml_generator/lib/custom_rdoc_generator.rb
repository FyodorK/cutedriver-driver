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

module Generators

  abort("") unless defined?( RDoc )

	class TDriverFeatureTestGenerator

    def initialize( options )

      @templates = {}

      @found_modules_and_methods = {}

      load_templates

      @options = options

      @already_processed_files = []

      @current_module_tests = []

      @current_module = nil

      @output = { :files => [], :classes => [], :modules => [], :attributes => [], :methods => [], :aliases => [], :constants => [], :requires => [], :includes => []}

      @errors = []

    end
   
    def help( topic )

      case topic

        when 'description'
<<-EXAMPLE
# == description
# This method returns "String" as return value
def my_method( arguments )
 return "string"
end
EXAMPLE

        when 'returns'
<<-EXAMPLE
# == returns
# String
#  description: example description
#  example: "string"
# 
def my_method( arguments )
 return "string"
end
EXAMPLE

        when 'arguments'
<<-EXAMPLE
# == arguments
# arg1
#  Integer
#   description: first argument can integer
#   example: 10
#  String
#   description: ... or string
#   example: "Hello"
#
# arg2
#  Array
#   description: MyArray
#   example: [1,2,3]
#   default: []
#
# *arg3
#  Array
#   description: MyMultipleArray
#   example: ['a','b','c']
#   default: []
#
# &block
#  Proc
#   description: MyMultipleArray
#   example: ['a','b','c']
#   default: []
def my_method( arg1, arg2, *arg3, &block )
  # ...
end
EXAMPLE

        when 'attr_argument'
<<-EXAMPLE
# == arguments
# value
#  Integer
#   description: first argument can integer
#   example: 10
attr_writer :my_attribute

or

# == arguments
# value
#  Integer
#   description: first argument can integer
#   example: 10
#  String
#   description: ... or string
#   example: "Hello"
attr_writer :my_attribute # ... when input value can be either Integer or String
EXAMPLE


        when 'exceptions'
<<-EXAMPLE
# == exceptions
# RuntimeError
#  description:  example exception #1
#
# ArgumentError
#  description:  example exception #2
def my_method

  # ...

end
EXAMPLE

        when 'behaviour_description'
<<-EXAMPLE
# == description
# This module contains demonstration implementation containing tags for documentation generation using gesture as an example
module MyBehaviour

  # ...

end
EXAMPLE

        when 'behaviour_name'
<<-EXAMPLE
# == behaviour
# MyPlatformSpecificBehaviour
module MyBehaviour

  # ...

end
EXAMPLE

        when 'behaviour_object_types'
<<-EXAMPLE
# == objects
# *
module MyBehaviour

  # apply behaviour to any test object, except SUT

end    

or

# == objects
# sut
module MyBehaviour

  # apply behaviour only to SUT object

end    

# == objects
# *;sut
module MyBehaviour

  # apply behaviour to any test object, including SUT

end    

or

# == objects
# MyObject
module MyBehaviour

  # apply behaviour only to objects which type is 'MyObject'

end    

or 

# == objects
# MyObject;OtherObject
module MyBehaviour

  # apply behaviour only to objects which type is 'MyObject' or 'OtherObject'
  # if more object types needed use ';' as separator.

end


EXAMPLE

        when 'behaviour_version'
<<-EXAMPLE
# == sut_version
# *
module MyBehaviour

  # any sut version 

end

or 

# == sut_version
# 1.0
module MyBehaviour

  # apply behaviour only to sut with version 1.0

end
EXAMPLE

        when 'behaviour_input_type'
<<-EXAMPLE
# == input_type
# *
module MyBehaviour

  # any input type 

end

or 

# == input_type
# touch
module MyBehaviour

  # apply behaviour only to sut which input type is 'touch'

end

or

# == input_type
# touch;key
module MyBehaviour

  # apply behaviour only to sut which input type is 'touch' or 'key'
  # if more types needed use ';' as separator.

end

EXAMPLE

        when 'behaviour_sut_type'
<<-EXAMPLE
# == sut_type
# *
module MyBehaviour

  # any input type 

end

or 

# == sut_type
# XX
module MyBehaviour

  # apply behaviour only to sut which sut type is 'XX'

end

or

# == sut_type
# XX;YY
module MyBehaviour

  # apply behaviour only to sut which sut type is 'XX' or 'YY'
  # if more types needed use ';' as separator.

end
EXAMPLE

        when 'behaviour_requires'
<<-EXAMPLE
# == requires
# *
module MyBehaviour

  # when no plugins required (TDriver internal/generic SUT behaviour)

end

or

# == requires
# testability-driver-my-plugin
module MyBehaviour

  # when plugin 'testability-driver-my-plugin' is required 

end
EXAMPLE

        when 'table_format'
        
<<-EXAMPLE
# == tables
# table_name
#  title: My table 1
#  |header1|header2|header3|
#  |1.1|1.2|1.3|
#  |2.1|2.2|2.3|
#  |3.1|3.2|3.3|
#
# another_table_name
#  title: My table 2
#  |id|value|
#  |0|true|
#  |1|false|
def my_method

  # ...

end
EXAMPLE
        


      else

        'Unknown help topic "%s"' % topic

      end

    end

    def self.for( options )

      new( options )

    end

    def load_templates

      Dir.glob( File.join( File.dirname( File.expand_path( __FILE__ ) ), '..', 'templates', '*.template' ) ).each{ | file |

        name = File.basename( file ).gsub( '.template', '' )

        @templates[ name ] = open( file, 'r' ).read

      }

    end

    def generate( files )

      # process files
      files.each{ | file |
        
        process_file( file ) unless @already_processed_files.include?( file.file_absolute_name )

      }

      # TODO: some other format for writing the hash to file...
      open("#{ $output_results_name }.hash", "w" ){ | file | file << @found_modules_and_methods.inspect }

    end

    def process_file( file )

      @module_path = []
      
      @current_file = file
  
      process_modules( file.modules )    

    end

    def process_modules( modules )

      modules.each{ | _module | 

        unless @already_processed_files.include?( _module.full_name )

          @module_path.push( _module.name )

          process_module( _module ) 

          @module_path.pop

        end

      }

    end

    def process_methods( methods )

      @processing = "method"

      results = []

      methods.each{ | method | 

        results << process_method( method )

      }

      Hash[ results ]

    end

    def process_method_arguments_section( source, params_array )

      result = []

      current_argument = nil

      current_argument_type = nil

      current_section = nil

      argument_index = -1

      source.lines.to_a.each_with_index{ | line, index | 
        
        # remove cr/lf
        line.chomp!

        # remove trailing whitespaces
        line.rstrip!

        # count nesting depth
        line.match( /^(\s*)/ )

        nesting = $1.size

        # remove leading whitespaces
        line.lstrip!

        if nesting == 0

          line =~ /^([*|&]{0,1}\w+(\#\w+?)*)$/i

          unless $1.nil?

            # argument name
            current_argument = $1 

            current_section = nil

            current_argument_type = nil

            result << { current_argument => { :argument_type_order => [], :types => {} } }

            argument_index += 1

          end

        else

          # is line content class name? (argument variable type)
          line =~ /^(.*)$/i

          if !$1.nil? && ( 65..90 ).include?( $1[0] ) && nesting == 1 # "Array", "String", "Integer"

            #Kernel.const_get( $1 ) rescue abort( "Line %s: \"%s\" is not valid argument variable type. (e.g. OK: \"String\", \"Array\", \"Fixnum\" etc) " % [ index +1, $1 ] )

            current_argument_type = $1

            result[ argument_index ][ current_argument ][ :argument_type_order ] << $1

            result[ argument_index ][ current_argument ][ :types ][ current_argument_type ] = {}

            #result[ argument_index ][ current_argument ][ current_argument_type ] = {}

            current_section = nil

          else

            abort("Unable add argument details (line %s: \"%s\") for \"%s\" due to argument variable type must be defined first.\nPlease note that argument type must start with capital letter (e.g. OK: \"String\" NOK: \"string\")" % [ index + 1, line, current_argument  ] ) if current_argument_type.nil?

            line =~ /^(.*?)\:{1}($|[\r\n\t\s]{1})(.*)$/i

            if $1.nil?

              abort("Unable add argument details (line %s: \"%s\") for \"%s\" due to section name not defined. Sections names are written in lowercase with trailing colon and whitespace (e.g. OK: \"example: 10\", NOK: \"example:10\")" % [ index +1, line, current_argument]) if $1.nil? && current_section.nil?

              # remove leading & trailing whitespaces
              section_content = line.strip

            else

              current_section = $1

              #unless result[ argument_index ][ current_argument ][ current_argument_type ].has_key?( current_section )
              unless result[ argument_index ][ current_argument ][ :types ][ current_argument_type ].has_key?( current_section )

                #result[ argument_index ][ current_argument ][ current_argument_type ][ current_section ] = ""
                result[ argument_index ][ current_argument ][ :types ][ current_argument_type ][ current_section ] = ""

              end
          
              section_content = $3.strip

            end

            abort("Unable add argument details due to argument not defined. Argument name must start from pos 1 of comment. (e.g. \"# my_variable\" NOK: \"#  my_variable\", \"#myvariable\")") if current_argument.nil?  

            # add one leading whitespace if current_section value is not empty 
            #section_content = " " + section_content unless result[ argument_index ][ current_argument ][ current_argument_type ][ current_section ].empty?
            section_content = " " + section_content unless result[ argument_index ][ current_argument ][ :types ][ current_argument_type ][ current_section ].empty?

            # store section_content to current_section
            #result[ argument_index ][ current_argument ][ current_argument_type ][ current_section ] << section_content
            result[ argument_index ][ current_argument ][ :types ][ current_argument_type ][ current_section ] << section_content

          end

        end

      }

      order = []
      
      params_array.collect{ | o | o.first }.each{ | param |
            
        if ( item = result.select{ | arg | arg.keys.include?( param ) }).empty?
                
          raise_error("Error: Argument '#{ param }' not documented in '#{ @current_method.name }' ($MODULE).\nNote that documented argument and variable name must be identical.", [ 'writer', 'accessor' ].include?( @processing ) ? 'attr_argument' : 'arguments' )

          order << { param => {} }

        else

          order << item.first
        
        end
      
      }
            

      # add block arguments if any   
      found_keys = order.collect{ | pair | pair.keys }.flatten

      missing = result.collect{ | value | 
      
        order << value unless found_keys.include?( value.keys.first )
      
        #p value.keys
      
      }

      #p "--", order, "--"
            
      order

    end

    def process_table( source )
    
      result = []
    
      #p source

      table_name = nil
      header_columns = 0

      source.lines.to_a.each_with_index{ | line, index | 

        # remove cr/lf
        line.chomp!

        # remove trailing whitespaces
        line.rstrip!

        # count nesting depth
        line.match( /^(\s*)/ )

        nesting = $1.size

        #puts "%s,%s: %s" % [ index, nesting, line ]

        # new table
        if nesting == 0

          unless line.empty?
          
            line =~ /^(\w+)/i

            result << { "name" => $1, "content" => [] }

            table_name = $1.to_s

          else
          
            table_name = nil

          end

        else

          line.lstrip!

          if line[0].chr == '|'

            unless table_name.nil?
              
              if line[-1].chr != '|'

                raise_error( "Malformed custom table #{ result.last[ "name" ]}, line '#{ line }' ($MODULE). Line must start and end with '|' character.", "table_format" ) 

              else

                line[0] = ""
                line[-1] = ""

                columns = line.split("|")

                unless result.last[ "content" ].empty?
                
                  raise_error( "Malformed custom table #{ result.last[ "name" ]}, line '#{ line }' ($MODULE). Number of columns (#{ columns.count }) does not match with header (#{ header_columns })", "table_format" ) if columns.count != header_columns 
                                  
                else
                  
                  header_columns = columns.count
                
                end

                result.last[ "content" ] << columns
              
              end

            else

              raise_error( "Malformed custom table #{ result.last[ "name" ]} ($MODULE). Table name is missing.", "table_format" ) 

            end
          
          else
                    
            unless line.empty?
                    
              line =~ /^(.*?)\:{1}($|[\r\n\t\s]{1})(.*)$/i

              if $1.to_s.empty?

                raise_error( "Malformed custom table #{ result.last[ "name" ]}, line '#{ line }' ($MODULE). Table section name (e.g title) is missing.", "table_format" ) 
                  
              else
  
                result.last[ $1.to_s ] = ( $3 || "" ).strip
      
              end
      
            else
          
              table_name = nil
            
            end
      
          end
          
        end
        
      }
            
      result
    
    end

    def process_formatted_section( source )

      result = []

      current_argument_type = nil

      current_section = nil

      argument_index = -1

      source.lines.to_a.each_with_index{ | line, index | 
        
        # remove cr/lf
        line.chomp!

        # remove trailing whitespaces
        line.rstrip!

        # count nesting depth
        line.match( /^(\s*)/ )

        nesting = $1.size

        # remove leading whitespaces
        line.lstrip!

        if nesting == 0

          line =~ /^(.+)/i

          if !$1.nil? && (65..90).include?( $1[0] )

            #Kernel.const_get( $1 ) rescue abort( "Line %s: \"%s\" is not valid argument variable type. (e.g. OK: \"String\", \"Array\", \"Fixnum\" etc) " % [ index + 1, $1 ] ) if verify_type

            # argument type
            current_argument_type = $1 || ""

            current_section = nil

            result << { current_argument_type => {} }

            argument_index += 1

          end

         else

            abort("Unable add value details (line %s: \"%s\") for %s due to detail type must be defined first.\nPlease note that return value and exception type must start with capital letter (e.g. OK: \"String\" NOK: \"string\")" % [ index + 1, line, current_argument_type  ] ) if current_argument_type.nil?

            line =~ /^(.*?)\:{1}($|[\r\n\t\s]{1})(.*)$/i

            if $1.nil?

              abort("Unable add value details (line %s: \"%s\") for %s due to section name not defined. Sections names are written in lowercase with trailing colon and whitespace (e.g. OK: \"example: 10\", NOK: \"example:10\")" % [ index +1, line, current_argument_type ]) if $1.nil? && current_section.nil?

              # remove leading & trailing whitespaces
              section_content = line.strip

            else

              current_section = $1
              
              unless result[ argument_index ][ current_argument_type ].has_key?( current_section )

                result[ argument_index ][ current_argument_type ][ current_section ] = ""

              end
          
              section_content = ( $3 || "" ).strip

            end

            abort("Unable add return value details due to variable type not defined. Argument type must be defined at pos 1 of comment. (e.g. \"# Integer\" NOK: \"#  Integer\", \"#Integer\")") if current_argument_type.nil?  

            # add one leading whitespace if current_section value is not empty 
            section_content = " " + section_content unless result[ argument_index ][ current_argument_type ][ current_section ].empty?

            # store section_content to current_section
            result[ argument_index ][ current_argument_type ][ current_section ] << section_content

        end


      }

      result

    end

    def store_to_results( module_name, name, type, params )

      unless @found_modules_and_methods.has_key?( module_name )

        @found_modules_and_methods[ module_name ] = []

      end
      
      #p params.select{ | param | param.last == false }
      #p params.select{ | param | param.last == true }

      #exit

      count = "%s;%s" % [ params.count, params.select{ | param | param.last == true }.count ]

      @found_modules_and_methods[ module_name ] << "%s#%s#%s" % [ name, type, count ] #{ :name => name, :type => type }

    end

    def process_arguments( arguments )

      arguments = arguments[ 1 .. -2 ] if arguments[0].chr == "(" and arguments[-1].chr ==")"

      arguments.strip!
      
      # tokenize string
      tokenizer = RubyLex.new( arguments )

      # get first token
      token = tokenizer.token

      # set previous token to nil by default
      previous_token = nil

      args = []

      capture = true
      capture_depth = []
      capture_default = false

      default_value = []

      # loop while tokens available
      while token

        if [ RubyToken::TkLBRACE, RubyToken::TkLPAREN, RubyToken::TkLBRACK ].include?( token.class )

          default_value << token.text if capture_default
        
          capture_depth << token
        
          capture = false

        elsif [ RubyToken::TkRBRACE, RubyToken::TkRPAREN, RubyToken::TkRBRACK ].include?( token.class )

          default_value << token.text if capture_default

          capture_depth.pop
          
          capture = true if capture_depth.empty?

        # argument name
        elsif capture == true

          # argument name
          if token.kind_of?( RubyToken::TkIDENTIFIER )

            args << [ token.name, nil, false ]

            # &blocks and *arguments are handled as optional parameters
            if [ RubyToken::TkBITAND, RubyToken::TkMULT ].include?( previous_token.class )
             #args.last[ 1 ] = previous_token.text 
  
             args.last[ 0 ] = previous_token.text + args.last[ 0 ] 
             args.last[ -1 ] = true 

            end
            
            default_value = []
            capture_default = false

          elsif token.kind_of?( RubyToken::TkCOMMA )
          
            capture_default = false
            
          # detect optional argument
          elsif token.kind_of?( RubyToken::TkASSIGN )

            capture_default = true

            # mark arguments as optional
            args.last[ -1 ] = true

          else

            default_value << token.text if capture_default && ![ RubyToken::TkSPACE, RubyToken::TkNL ].include?( token.class )
          
          end

        else
        
          default_value << token.text if capture_default && ![ RubyToken::TkSPACE, RubyToken::TkNL ].include?( token.class )
        
        end

        unless default_value.empty? 
      
          args.last[ 1 ] = default_value.join("")

        end

        # store previous token
        previous_token = token

        # get next token
        token = tokenizer.token

      end

      args

    end
    
  def process_undocumented_method_arguments( params )

    params.collect{ | param |
    
      { param.first.to_s => { :types => { "" => { "default" => param[1] } } } }
        
    }

  end


    def process_method( method )

      results = []

      method_header = nil

      if ( method.visibility == :public && @module_path.first =~ /MobyBehaviour/ )

        params = method.kind_of?( RDoc::Attr ) ? [] : process_arguments( method.params )

        @current_method = method

        method_header = process_comment( method.comment )

        ## TODO: remember to verify that there are documentation for each argument!
        ## TODO: verify that there is a tag for visualizer example

        method_header = Hash[ method_header.collect{ | key, value |

          if key == :arguments

            value = process_method_arguments_section( value, params )

          end

          if key == :returns

            value = process_formatted_section( value )
    
          end

          if key == :exceptions

            value = process_formatted_section( value )

          end
          
          if key == :tables
          
              value = process_table( value )
          
          end


          [ key, value ]

        }]

        # if no description found for arguments, add argument names to method_header hash
        if ( params.count > 0 ) && ( method_header[:arguments].nil? || method_header[:arguments].empty? )
                
          #p params.count, 
          method_header[:arguments] = process_undocumented_method_arguments( params )
          
        end


        method_name = method.name.clone

        type = "method"

        if method.kind_of?( RDoc::Attr )

          case method.rw

            when "R"
              type = "reader"
              #store_to_results( @module_path.join("::"), method.name, type )
            when "W"
              type = "writer"
              method_name << "="
              #store_to_results( @module_path.join("::"), method.name + "=", type )
            when "RW"
              type = "accessor"
              method_name << ";#{ method_name }="
              #store_to_results( @module_path.join("::"), method.name + "=", type )

          else

            raise_error( "Unknown attribute format for '#{ method.name }' ($MODULE). Expected 'R' (attr_reader), 'W' (attr_writer) or 'RW' (attr_accessor), got: '#{ method.rw }'" )

          end

          #store_to_results( @module_path.join("::"), method.name, type )

          method_header.merge!( :__type => type )

        else

          method_header.merge!( :__type => "method" )

          
        end

        store_to_results( @module_path.join("::"), method.name, type, params )

        # do something
        [ method_name, method_header ]

      else

        nil
    
      end

    end

    # verify if 
    def has_method?( target, method_name )

        target.method_list.select{ | method | 
        
          method.name == method_name 
          
        }.count > 0
    
    end
    
    def encode_string( string )
    
      return "" if string.nil? 
    
      result = "%s" % string
    
      result.gsub!( /\&/, '&amp;' )
      result.gsub!( /\</, '&lt;' )
      result.gsub!( /\>/, '&gt;' )
      result.gsub!( /\"/, '&quot;' )
      result.gsub!( /\'/, '&apos;' )
    
      result
    
    end

    def process_attributes( attributes )

      @processing = :attributes

      results = []

      attributes.each{ | attribute | 

        #p attribute.comment

        results << process_method( attribute )

        # TODO: tapa miten saadaan attribuuttien getteri ja setteri dokumentoitua implemenaatioon

      }

      Hash[ results ]

    end

    def process_comment( comment )

      header = {}

      current_section = nil

      return header if comment.nil? || comment.empty?

      comment.each_line{ | line |

        # remove '#' char from beginning of line
        line.slice!( 0 )

        # if next character is whitespace assume that this is valid comment line
        # NOTE: that if linefeed is required use "#<#32><#10>"
        if [ 32 ].include?( line[ 0 ] )

          # remove first character
          line.slice!( 0 )

          # if line is a section header
          if line[ 0..2 ] == "== "

            # remove section header indicator string ("== ")
            line.slice!( 0..2 )

            # remove cr/lf
            line.gsub!( /[\n\r]/, "" )

            current_section = line.to_sym

          else

            unless current_section.nil?

              # remove cr/lf 
              # NOTE: if crlf is required use '\n'
              line.gsub!( /[\n\r]/, "" )

              # store to header hash
              if header.has_key?( current_section )

                header[ current_section ] << "\n" << ( line.rstrip )

              else

                header[ current_section ] = line.rstrip

              end

            else

              #puts "[nodoc?] %s" % line

            end

          end

        else

          #puts "[nodoc] %s" % line

        end

      }

      header

    end

    def apply_macros!( source, macros )
        
      macros.each_pair{ | key, value |
                  
        source.gsub!( /(\$#{ key })\b/, value || "" )
      
      }
      
      source
    
    end

    def raise_error( text, topic = nil )

      type = ( @processing == "method" ) ? "method" : "attribute"

      text.gsub!( '$TYPE', type )

      text.gsub!( '$MODULE', @current_module.full_name )

      text = "=========================================================================================================\n" <<
        "File: #{ @module_in_files.join(", ") }\n" << text << "\n\nExample:\n\n"

      text << help( topic ) unless topic.nil?

      #warn( text << "\n" )

    end

    def generate_return_values_element( header, feature )

      return "" if ( [ 'writer' ].include?( feature.last[ :__type ] ) )

      return if feature.last[ :returns ].nil? || feature.last[ :returns ].empty?

      if feature.last[ :returns ].nil?

        raise_error("Error: $TYPE '#{ feature.first }' ($MODULE) doesn't have return value type(s) defined", 'returns' )

      end

      # generate return value types template
      returns = feature.last[ :returns ].collect{ | return_types |
            
        return_types.collect{ | returns |
        
           # apply types to returns template
           apply_macros!( @templates["behaviour.xml.returns"].clone, {
              "RETURN_VALUE_TYPE" => encode_string( returns.first ),
              "RETURN_VALUE_DESCRIPTION" => encode_string( returns.last["description"] ),
              "RETURN_VALUE_EXAMPLE" => encode_string( returns.last["example"] ),
            }
           )
          
        }.join
     
      }.join

      apply_macros!( @templates["behaviour.xml.method.returns"].clone, {

          "METHOD_RETURNS" => returns

        }
      )
      
    end

    def generate_exceptions_element( header, feature )

      return "" if ( feature.last[:__type] != 'method' )

      if feature.last[ :exceptions ].nil?

        raise_error("Error: $TYPE '#{ feature.first }' ($MODULE) doesn't have exceptions(s) defined", 'exceptions' )

      end

      return "" if feature.last[ :exceptions ].nil? || feature.last[ :exceptions ].empty?

      # generate exceptions template
      exceptions = feature.last[ :exceptions ].collect{ | exceptions |
      
        exceptions.collect{ | exception |
        
           # apply types to exception template
           apply_macros!( @templates["behaviour.xml.exception"].clone, {
              "EXCEPTION_NAME" => encode_string( exception.first ),
              "EXCEPTION_DESCRIPTION" => encode_string( exception.last["description"] )
            }
           )
          
        }.join
     
      }.join

      apply_macros!( @templates["behaviour.xml.method.exceptions"].clone, {

          "METHOD_EXCEPTIONS" => exceptions

        }
      )

    end

    def generate_arguments_element( header, feature )

      return "" if ( feature.last[:__type] == 'reader' )

      argument_types = { "*" => "multi", "&" => "block" }
      argument_types.default = "normal"

      #return "" if ( @processing == :attributes && feature.last[:__type] == 'R' )

      if feature.last[ :arguments ].nil?

        note = ". Note that also attribute writer requires input value defined as argument." if [ 'writer', 'accessor' ].include?( @processing )

        raise_error("Error: $TYPE '#{ feature.first }' ($MODULE) doesn't have arguments(s) defined#{ note }", [ 'writer', 'accessor' ].include?( @processing ) ? 'attr_argument' : 'arguments' )

      end

      # generate arguments xml
      arguments = ( feature.last[:arguments] || {} ).collect{ | arg |
                
        # generate argument types template
        arg.collect{ | argument |

         argument_type = argument_types[ argument.first[0].chr ]
         argument_name = "%s" % argument.first          
         argument_name[0]="" if argument_types.has_key?( argument_name[0].chr )

         argument_type = "block_argument" if argument_type == "block" && argument_name.include?( "#" )          

         default_value_set = false 
         default_value = nil
                    
         if argument.last.has_key?( :argument_type_order )
           argument_types_in_order = argument.last[:argument_type_order].collect{ | type |                      
            [ type, argument.last[:types][ type ] ]           
           }
         else         
           argument_types_in_order = argument.last[:types] 
         end
                    
         types_xml = argument_types_in_order.collect{ | type |

           unless type.last["default"].nil?

             # show warning if default value for optional argument is already set
             raise_error( "Error: Default value for optional argument '%s' ($MODULE) is already set! ('%s' --> '%s')" % [ argument.first, default_value, type.last["default"] ] ) if default_value_set == true

             default_value = type.last["default"]
             default_value_set = true

           end

           if type.last["description"].nil?

            raise_error("Warning: Argument description for '%s' ($MODULE) is empty." % [ argument.first ], 'argument' )

           end

           if type.last["example"].nil?

            raise_error("Warning: Argument '%s' ($MODULE) example is empty." % [ argument.first ])

           end

           apply_macros!( @templates["behaviour.xml.argument_type"].clone, {
            
              "ARGUMENT_TYPE" => encode_string( argument_type == 'block' ? "Proc" : type.first ),
              "ARGUMENT_DESCRIPTION" => encode_string( type.last["description"] ),
              "ARGUMENT_EXAMPLE" => encode_string( type.last["example"] ),
           
            }
           )
         
         }.join

        if argument_type == "multi"
        
          default_value = "[]"
          default_value_set = true
        
        end
         
        if default_value_set

          default_value = apply_macros!( @templates["behaviour.xml.argument.default"].clone, { 
            "ARGUMENT_DEFAULT_VALUE" => encode_string( default_value || "" )
            }
          )

        else

          default_value = ""

        end

         # apply types to arguments template
         apply_macros!( @templates["behaviour.xml.argument"].clone, {
            "ARGUMENT_NAME" => encode_string( argument_name ),
            "ARGUMENT_TYPE" => encode_string( argument_type ),
            "ARGUMENT_TYPES" => types_xml,
            "ARGUMENT_DEFAULT_VALUE" => default_value.to_s,
            "ARGUMENT_OPTIONAL" => encode_string( argument_type == "multi" ? "true" : default_value_set.to_s )
          }
         )
        
        }.join
      
      }.join

      apply_macros!( @templates["behaviour.xml.method.arguments"].clone, {

          "METHOD_ARGUMENTS" => arguments

        }
      )


    end
    
    def generate_tables_element( header, features )
    
      tables = []
    
      unless features.last[:tables].nil? #[:tables]
        
        tables = features.last[:tables].collect{ | table |

          header = table[ "content" ].first.collect{ | header_item |
            apply_macros!( @templates["behaviour.xml.table.item"].clone, {
                "ITEM" => encode_string( header_item )
              }
            )
          }

          rows = table[ "content" ][ 1 .. -1 ].collect{ | row |

            row_items = row.collect{ | row_item |
            
              apply_macros!( @templates["behaviour.xml.table.item"].clone, {
                  "ITEM" => encode_string( row_item )
                }
              )
            }

            apply_macros!( @templates["behaviour.xml.table.row"].clone, {

              "TABLE_ROW_ITEMS" => row_items.join("") 
            
              }
            )
                        
          }


          apply_macros!( @templates["behaviour.xml.table"].clone, {
              "TABLE_NAME" => encode_string( table[ "name" ] ),
              "TABLE_TITLE" => encode_string( table[ "title" ] ),
              "TABLE_HEADER_ITEMS" => header.join(""),
              "TABLE_ROWS" => rows.join("")
            }
          )
        }

      end
    
      apply_macros!( @templates["behaviour.xml.method.tables"].clone, {

          "METHOD_TABLES" => tables.join("")

        }
      )
    
    end

    def generate_methods_element( header, features )

      # collect method and attribute templates
      methods = features.collect{ | feature_set |
      
        feature_set.collect{ | feature |
                  
          @processing = feature.last[:__type]
            
          # TODO: tarkista lähdekoodista että onko argument optional vai ei
          # TODO: tarkista että onko kaikki argumentit dokumentoitu
          
          arguments = generate_arguments_element( header, feature )

          returns = generate_return_values_element( header, feature )

          exceptions = generate_exceptions_element( header, feature )
                    
          tables = generate_tables_element( header, feature )
                    
          if feature.last[:description].nil?

           raise_error("Warning: $TYPE description for '#{ feature.first }' ($MODULE) is empty.", 'description')

          end
                              
          # generate method template            
          apply_macros!( @templates["behaviour.xml.method"].clone, { 
            "METHOD_NAME" => encode_string( feature.first ),
            "METHOD_TYPE" => encode_string( feature.last[:__type] || "unknown" ),
            "METHOD_DESCRIPTION" => encode_string( feature.last[:description] ),
            "METHOD_ARGUMENTS" => arguments,
            "METHOD_RETURNS" => returns,
            "METHOD_EXCEPTIONS" => exceptions,
            "METHOD_TABLES" => tables,
            "METHOD_INFO" => encode_string( feature.last[:info] )
           } 
          )

        }.join
      
      }.join


    end

    def generate_behaviour_element( header, methods )

      # verify that behaviour description is defined
      unless header.has_key?(:description)

         raise_error("Warning: Behaviour description for $MODULE is empty.", 'behaviour_description' ) unless methods.empty?

      end

      # verify that behaviour name is defined
      unless header.has_key?(:behaviour)

         raise_error("Warning: Behaviour name for $MODULE is not defined.", 'behaviour_name' ) unless methods.empty?

      end

      # verify that behaviour object type(s) is defined
      unless header.has_key?(:objects)

         raise_error("Warning: Behaviour object type(s) for $MODULE is not defined.", 'behaviour_object_types' ) unless methods.empty?

      end

      # verify that behaviour sut type(s) is defined
      unless header.has_key?(:sut_type)

         raise_error("Warning: Behaviour SUT type for $MODULE is not defined.", 'behaviour_sut_type' ) unless methods.empty?

      end

      # verify that behaviour input type(s) is defined
      unless header.has_key?(:input_type)

         raise_error("Warning: Behaviour input type for $MODULE is not defined.", 'behaviour_input_type' ) unless methods.empty?

      end

      # verify that behaviour sut version(s) is defined
      unless header.has_key?(:sut_version)

         raise_error("Warning: Behaviour SUT version for $MODULE is not defined.", 'behaviour_version' ) unless methods.empty?

      end

      # verify that behaviour sut version(s) is defined
      unless header.has_key?(:requires)

         raise_error("Warning: Required plugin name is not defined for $MODULE.", 'behaviour_requires' ) unless methods.empty?

      end

      # apply header
      text = apply_macros!( @templates["behaviour.xml"].clone, { 
        "REQUIRED_PLUGIN" => encode_string( header[:requires] ),
        "BEHAVIOUR_NAME" => encode_string( header[:behaviour] ),
        "BEHAVIOUR_METHODS" => methods,
        "OBJECT_TYPE" => encode_string( header[:objects] ),
        "SUT_TYPE" => encode_string( header[:sut_type] ),
        "INPUT_TYPE" => encode_string( header[:input_type] ),
        "VERSION" => encode_string( header[:sut_version] ),
        "MODULE_NAME" => encode_string( @module_path.join("::") )
        } 
      )    
    
      # remove extra linefeeds
      text.gsub!( /^[\n]+/, "\n" )

      text.gsub!( /^(\s)*$/, "" )

      text

    end

    def generate_behaviour( header, *features )

      methods = generate_methods_element( header, features )

      generate_behaviour_element( header, methods )

    end

    def process_module( _module )

      @already_processed_files << _module.full_name

      # skip if not a behaviour module      
      return if /^MobyBehaviour.*/ !~ _module.full_name.to_s

      module_header = process_comment( _module.comment )

      # store information where module is stored
      @module_in_files = _module.in_files.collect{ | file | file.file_absolute_name }

      #unless module_header.empty?

        @current_module = _module

        # process methods
        methods = process_methods( _module.method_list )

        # process attributes
        attributes = process_attributes( _module.attributes )

        print "  ... %s" % module_header[:behaviour]

        xml = generate_behaviour( module_header, methods, attributes ) 

        xml_file_name = '%s.%s' % [ module_header[:behaviour], 'xml' ]

        begin

          if xml_file_name != '.xml' 

            open( xml_file_name, 'w'){ | file | file << xml }

            puts ".xml"

          else

            warn("Skip: #{ @module_path.join("::") } XML not saved due to missing behaviour name/description ") #in #{ @module_in_files.join(", ") }")

          end

        rescue Exception => exception

          warn("Warning: Error writing file %s (%s: %s)" % [ xml_file_name, exception.class, exception.message ] )

        end

      #end

      # process if any child modules 
      process_modules( _module.modules ) unless _module.modules.empty?

    end

  end

end

