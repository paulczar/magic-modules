#!/usr/bin/env ruby
# Copyright 2017 Google Inc.
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

$LOAD_PATH.unshift File.dirname(__FILE__)

# Run from compiler dir so all references are relative to the compiler
# executable. This allows the following command line:
#   puppet-google-compute$ ../puppet-codegen/compiler products/compute $PWD
Dir.chdir(File.dirname(__FILE__))

# Our default timezone is UTC, to avoid local time compromise test code seed
# generation.
ENV['TZ'] = 'UTC'

require 'api/compiler'
require 'google/logger'
require 'optparse'
require 'provider/ansible'
require 'provider/ansible/bundle'
require 'provider/chef'
require 'provider/chef/bundle'
require 'provider/example'
require 'provider/puppet'
require 'provider/puppet/bundle'
require 'provider/terraform'
require 'provider/terraform_example'
require 'pp' if ENV['COMPILER_DEBUG']

product_names = nil
all_products = false
output_path = nil
provider_name = nil
force_provider = nil
types_to_generate = []
version = nil

ARGV << '-h' if ARGV.empty?
Google::LOGGER.level = Logger::INFO

# rubocop:disable Metrics/BlockLength
OptionParser.new do |opt|
  opt.on('-p', '--product PRODUCT', Array, 'Folder[,Folder...] with product catalog') do |p|
    product_names = p
  end
  opt.on('-a', '--all', 'Build all products. Cannot be used with --product.') do
    all_products = true
  end
  opt.on('-o', '--output OUTPUT', 'Folder for module output') do |o|
    output_path = o
  end
  opt.on('-e', '--engine ENGINE', 'Provider ("engine") to build') do |e|
    provider_name = e
  end
  opt.on('-f', '--force PROVIDER', 'Force using a non-default provider') do |e|
    force_provider = e
  end
  opt.on('-t', '--type TYPE[,TYPE...]', Array, 'Types to generate') do |t|
    types_to_generate = t
  end
  opt.on('-v', '--version VERSION', 'API version to generate') do |v|
    version = v
  end
  opt.on('-h', '--help', 'Show this message') do
    puts opt
    exit
  end
  opt.on('-d', '--debug', 'Show all debug logs') do |_debug|
    Google::LOGGER.level = Logger::DEBUG
  end
end.parse!
# rubocop:enable Metrics/BlockLength

raise 'Cannt use -p/--products and -a/--all simultaneously' if product_names && all_products
raise 'Either -p/--products OR -a/--all must be present' if product_names.nil? && !all_products
raise 'Option -o/--output is a required parameter' if output_path.nil?
raise 'Option -e/--engine is a required parameter' if provider_name.nil?

if all_products
  product_names = []
  Dir["products/**/#{provider_name}.yaml"].each do |file_path|
    product_names.push(File.dirname(file_path))
  end

  raise "No #{provider_name}.yaml files found. Check provider/engine name." if product_names.empty?
end

# rubocop:disable Metrics/BlockLength
product_names.each do |product_name|
  product_yaml_path = File.join(product_name, 'api.yaml')
  raise "Product '#{product_name}' does not have an api.yaml file" \
    unless File.exist?(product_yaml_path)

  provider_yaml_path = File.join(product_name, "#{provider_name}.yaml")
  raise "Product '#{product_name}' does not have a #{provider_name}.yaml file" \
    unless File.exist?(provider_yaml_path)

  raise "Output path '#{output_path}' does not exist or is not a directory" \
    unless Dir.exist?(output_path)

  Google::LOGGER.info "Compiling '#{product_name}' output to '#{output_path}'"
  Google::LOGGER.info \
    "Generating types: #{types_to_generate.empty? ? 'ALL' : types_to_generate}"

  product_api = Api::Compiler.new(product_yaml_path).run
  product_api.validate
  pp product_api if ENV['COMPILER_DEBUG']

  provider_config = \
    Provider::Config.parse(provider_yaml_path, product_api, version)
  pp provider_config if ENV['COMPILER_DEBUG']

  if force_provider.nil?
    provider = provider_config.provider.new(provider_config, product_api)

  else
    override_providers = {
      'examples' => Provider::TerraformExample
    }

    provider_class = override_providers[force_provider]
    raise "Invalid force provider option #{force_provider}" \
      if provider_class.nil?

    provider = \
      override_providers[force_provider].new(provider_config, product_api)
  end
  provider.generate output_path, types_to_generate, version
end
# rubocop:enable Metrics/BlockLength
