class Ability
  include Hydra::Ability
  
  include Hyrax::Ability
  self.ability_logic += [
    :everyone_can_create_curation_concerns,
    :create_content
  ]

  # Define any customized permissions here.
  def custom_permissions
    # Limits deleting objects to a the admin user
    #
    # if current_user.admin?
    #   can [:destroy], ActiveFedora::Base
    # end

    # Limits creating new objects to a specific group
    #
    # if user_groups.include? 'special_group'
    #   can [:create], ActiveFedora::Base
    # end
    if current_user.admin?
      can [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy], Role
    end
  end

  def create_content
    # everyone who is logged in can create content
    # return unless registered_user?
    can :create, ::Dataset if current_user
  end
end
