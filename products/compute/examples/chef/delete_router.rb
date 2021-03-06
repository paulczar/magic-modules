<%# The license inside this applies to this file
# Copyright 2018 Google Inc.
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
-%>
<% if name != 'README.md' -%>

<%= compile 'templates/license.erb' -%>

<%= lines(autogen_notice :chef) -%>

<%= compile 'templates/chef/example~auth.rb.erb' -%>

<% else # name == README.md -%>
# Router requires a network so define one in your recipe:
#   - gcompute_network 'my-network' do ... end
<% end # name == README.md -%>
gcompute_router <%= example_resource_name('my-router') -%> do
  action :delete
  region 'us-west1'
  project ENV['PROJECT'] # ex: 'my-test-project'
  credential 'mycred'
end
