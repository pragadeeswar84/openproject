# frozen_string_literal: true

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
require_module_spec_helper

RSpec.describe "create folder command" do
  using Storages::Peripherals::ServiceResultRefinements

  shared_examples_for "basic command setup" do
    it "is registered as commands.create_folder" do
      expect(Storages::Peripherals::Registry
               .resolve("#{storage.short_provider_type}.commands.create_folder")).to eq(described_class)
    end

    it "responds to #call with correct parameters" do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage],
                                                   %i[keyreq auth_strategy],
                                                   %i[keyreq folder_name],
                                                   %i[keyreq parent_location])
    end
  end

  shared_examples_for "successful folder creation" do
    it "creates a folder" do
      result = described_class.call(storage:, auth_strategy:, folder_name:, parent_location:)

      result.match(
        on_success: ->(response) do
          expect(response).to be_a(Storages::StorageFile)
          expect(response.name).to eq(folder_name)
          expect(response.location).to eq(path)
        end,
        on_failure: ->(error) { fail "Expected success, got #{error}" }
      )
    ensure
      delete_created_folder(storage, result.result)
    end
  end

  shared_examples_for "parent not found" do
    it "returns a failure" do
      result = described_class.call(storage:, auth_strategy:, folder_name:, parent_location:)

      result.match(
        on_failure: ->(error) do
          expect(error.code).to eq(:not_found)
          expect(error.data.source).to eq(error_source)
        end,
        on_success: ->(result) { fail "Expected failure, got #{result}" }
      )
    end
  end

  shared_examples_for "folder already exists" do
    it "returns a failure" do
      result = described_class.call(storage:, auth_strategy:, folder_name:, parent_location:)

      result.match(
        on_failure: ->(error) do
          expect(error.code).to eq(:conflict)
          expect(error.data.source).to eq(error_source)
        end,
        on_success: ->(result) { fail "Expected failure, got #{result}" }
      )
    end
  end

  describe Storages::Peripherals::StorageInteraction::OneDrive::CreateFolderCommand, :vcr, :webmock do
    let(:storage) { create(:sharepoint_dev_drive_storage) }
    let(:auth_strategy) do
      Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthClientCredentials.strategy
    end

    it_behaves_like "basic command setup"

    context "when creating a folder in the root", vcr: "one_drive/create_folder_root" do
      let(:folder_name) { "Földer CreatedBy Çommand" }
      let(:parent_location) { Storages::Peripherals::ParentFolder.new("/") }
      let(:path) { "/#{folder_name}" }

      it_behaves_like "successful folder creation"
    end

    context "when creating a folder in a parent folder", vcr: "one_drive/create_folder_parent" do
      let(:folder_name) { "Földer CreatedBy Çommand" }
      let(:parent_location) { Storages::Peripherals::ParentFolder.new("01AZJL5PKU2WV3U3RKKFF2A7ZCWVBXRTEU") }
      let(:path) { "/Folder with spaces/#{folder_name}" }

      it_behaves_like "successful folder creation"
    end

    context "when creating a folder in a non-existing parent folder", vcr: "one_drive/create_folder_parent_not_found" do
      let(:folder_name) { "Földer CreatedBy Çommand" }
      let(:parent_location) { Storages::Peripherals::ParentFolder.new("01AZJL5PKU2WV3U3RKKFF4A7ZCWVBXRTEU") }
      let(:error_source) { described_class }

      it_behaves_like "parent not found"
    end

    context "when folder already exists", vcr: "one_drive/create_folder_already_exists" do
      let(:folder_name) { "Folder" }
      let(:parent_location) { Storages::Peripherals::ParentFolder.new("/") }
      let(:error_source) { described_class }

      it_behaves_like "folder already exists"
    end
  end

  describe Storages::Peripherals::StorageInteraction::Nextcloud::CreateFolderCommand, :vcr, :webmock do
    let(:user) { create(:user) }
    let(:storage) do
      create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
    end
    let(:auth_strategy) do
      Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
    end

    it_behaves_like "basic command setup"

    context "when creating a folder in the root", vcr: "nextcloud/create_folder_root" do
      let(:folder_name) { "Földer CreatedBy Çommand" }
      let(:parent_location) { Storages::Peripherals::ParentFolder.new("/") }
      let(:path) { "/#{folder_name}" }

      it_behaves_like "successful folder creation"
    end

    context "when creating a folder in a parent folder", vcr: "nextcloud/create_folder_parent" do
      let(:folder_name) { "Földer CreatedBy Çommand" }
      let(:parent_location) { Storages::Peripherals::ParentFolder.new("/Folder") }
      let(:path) { "/Folder/#{folder_name}" }

      it_behaves_like "successful folder creation"
    end

    context "when creating a folder in a non-existing parent folder", vcr: "nextcloud/create_folder_parent_not_found" do
      let(:folder_name) { "New Folder" }
      let(:parent_location) { Storages::Peripherals::ParentFolder.new("/DeathStar3") }
      let(:error_source) { described_class }

      it_behaves_like "parent not found"
    end

    context "when folder already exists", vcr: "nextcloud/create_folder_already_exists" do
      let(:folder_name) { "Folder" }
      let(:parent_location) { Storages::Peripherals::ParentFolder.new("/") }
      let(:error_source) { described_class }

      it_behaves_like "folder already exists"
    end
  end

  private

  def delete_created_folder(storage, folder)
    location = if storage.provider_type_nextcloud?
                 folder.location
               else
                 folder.id
               end

    Storages::Peripherals::Registry
      .resolve("#{storage.short_provider_type}.commands.delete_folder")
      .call(storage:, auth_strategy:, location:)
  end
end
