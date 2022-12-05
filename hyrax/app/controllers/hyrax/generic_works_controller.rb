# Generated via
#  `rails generate hyrax:work GenericWork`
module Hyrax
  # Generated controller for GenericWork
  class GenericWorksController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    include ControllerUtils
    self.curation_concern_type = ::GenericWork

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::GenericWorkPresenter

    def show
      show_common_works
    end

    def edit
      # We do not want to edit previous values of editorial note
      @curation_concern.editorial_note = ''
      super
    end

    def create
      add_date_and_creator_to_note
      super
    end

    def update
      add_date_and_creator_to_note
      super
    end

    private
    def add_date_and_creator_to_note
      if params['generic_work'].include?('editorial_note') and params['generic_work']['editorial_note'].present?
        notes = []
        notes = JSON.parse(@curation_concern.editorial_note) if @curation_concern.editorial_note.present?
        notes = [notes] unless notes.is_a? Array
        params['generic_work']['editorial_note'] = notes.append(
          {'note': params['generic_work']['editorial_note'], created: Time.now, user_id: current_user.email, user_name: current_user.name}
        ).to_json
      end
    end
  end
end
