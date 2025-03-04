#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Project Custom Field Mappings", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:non_admin) { create(:user) }
  shared_let(:project) { create(:project) }
  shared_let(:project_custom_field) { create(:project_custom_field) }
  shared_let(:project_custom_field_mapping) { create(:project_custom_field_project_mapping, project_custom_field:, project:) }

  let(:project_custom_field_mappings_page) { Pages::Admin::Settings::ProjectCustomFields::ProjectCustomFieldMappingsIndex.new }

  context "with insufficient permissions" do
    it "is not accessible" do
      login_as(non_admin)
      visit project_mappings_admin_settings_project_custom_field_path(project_custom_field)

      expect(page).to have_text("You are not authorized to access this page.")
    end
  end

  context "with sufficient permissions" do
    before do
      login_as(admin)
      visit project_mappings_admin_settings_project_custom_field_path(project_custom_field)
    end

    it "renders the project custom field mappings page" do
      aggregate_failures "shows a correct breadcrumb menu" do
        within ".PageHeader-breadcrumbs" do
          expect(page).to have_link("Administration")
          expect(page).to have_link("Projects")
          expect(page).to have_link("Project attributes")
          expect(page).to have_text(project_custom_field.name)
        end
      end

      aggregate_failures "shows tab navigation" do
        within_test_selector("project_attribute_detail_header") do
          expect(page).to have_link("Details")
          expect(page).to have_link("Projects")
        end
      end

      aggregate_failures "shows the correct project mappings" do
        within "#project-table" do
          expect(page).to have_text(project.name)
        end
      end

      aggregate_failures "allows to unlinking a project" do
        project_custom_field_mappings_page.click_menu_item_of("Deactivate for this project", project)

        expect(page).to have_no_text(project.name)
      end
    end

    context "and the project custom field is required" do
      shared_let(:project_custom_field) { create(:project_custom_field, is_required: true) }

      it "renders a blank slate" do
        expect(page).to have_text("Required in all projects")
      end
    end
  end
end
