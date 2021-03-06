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

require 'provider/terraform'

module Provider
  # Code generator for runnable Terraform Examples
  class TerraformExample < Provider::Terraform
    # We don't want *any* static generation, so we override generate to only
    # generate objects.
    def generate(output_folder, types, version_name)
      version = @api.version_obj_or_default(version_name)
      generate_objects(output_folder, types, version)
    end

    # Create a directory of examples per resource
    def generate_resource(data)
      return if data[:object].example.nil?

      data[:object].example.each do |example|
        target_folder = data[:output_folder]
        target_folder = File.join(target_folder, example.name)
        FileUtils.mkpath target_folder

        generate_resource_file data.clone.merge(
          example: example,
          default_template: 'templates/terraform/examples/base_configs/example_file.tf.erb',
          out_file: File.join(target_folder, 'main.tf')
        )

        generate_resource_file data.clone.merge(
          default_template: 'templates/terraform/examples/base_configs/example_backing_file.tf.erb',
          out_file: File.join(target_folder, 'name_prefix.tf')
        )
      end
    end

    # rubocop:disable Layout/EmptyLineBetweenDefs
    # We don't want to generate anything but the resource.
    def generate_resource_tests(data) end
    def generate_network_datas(data, object) end
    def generate_base_property(data) end
    def generate_simple_property(type, data) end
    def emit_nested_object(data) end
    def emit_resourceref_object(data) end
    def generate_typed_array(data, prop) end
    # rubocop:enable Layout/EmptyLineBetweenDefs
  end
end
