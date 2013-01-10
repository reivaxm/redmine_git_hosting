module GitHosting
  module Patches
    module RepositoriesControllerPatch
      def show_with_git_instructions
        if @repository.is_a?(Repository::Git) and @repository.entries(@path, @rev).blank?
          render :action => 'git_instructions'
        else
          show_without_git_instructions
        end
      end

      def create_with_scm_settings
        GitHosting.logger.debug "On create_with_scm_settings"
        params[:repository] ||= {}

        # Add url base on GitHosting
        if params[:repository_scm] == "Git"
          params[:repository][:url] = GitHosting.repository_path(@project)
        end

        #Create Repository
        if params[:repository_scm] == "Git" || @project.repository.is_a?(Repository::Git)
          @repository = Repository.factory(params[:repository_scm])
          @repository.project = @project if @repository
          if request.post? && @repository
            @repository.attributes = params[:repository]
            if !params[:extra].nil?
              #@repository.extra.update_attributes(params[:extra])
              @repository.merge_extra_info(params[:extra])
            end
            @repository.save
            @project.reload #needed to reload association
            redirect_to settings_project_path(@project, :tab => 'repositories')
          else
            render :action => :new
          end

          unless @project.repository.nil?
            GitHostingObserver.bracketed_update_repositories(@project) 
          end
        else
          create_without_scm_settings
        end

        GitHostingObserver.set_update_active(true);
      end

      def edit_with_scm_settings
        GitHosting.logger.debug "On edit_with_scm_settings"
      end

      def update_with_scm_settings
        GitHosting.logger.debug "On update_with_scm_settings"

        # Turn off updates during repository update
        GitHostingObserver.set_update_active(false);
        params[:repository] ||= {}

        if params[:repository_scm] == "Git"
          params[:repository][:url] = GitHosting.repository_path(@project)
        end

        if params[:repository_scm] == "Git" || @project.repository.is_a?(Repository::Git)
          @repository = Repository.factory(params[:repository_scm])
          @repository.project = @project if @repository
          if request.put? && @repository
            @repository.attributes = params[:repository]
            if !params[:extra].nil?
              #@repository.extra.update_attributes(params[:extra])
              @repository.merge_extra_info(params[:extra])
            end
            @repository.save
            @project.reload #needed to reload association
            redirect_to settings_project_path(@project, :tab => 'repositories')
          else
            render :action => 'edit'
          end

          unless @project.repository.nil?
            GitHostingObserver.bracketed_update_repositories(@project) 
          end
        else
          edit_without_scm_settings
        end

        GitHostingObserver.set_update_active(true);
      end

      def self.included(base)
        base.class_eval do
          unloadable
        end
        base.send(:alias_method_chain, :show, :git_instructions)
        base.send(:alias_method_chain, :create, :scm_settings)
        base.send(:alias_method_chain, :edit, :scm_settings)
        base.send(:alias_method_chain, :update, :scm_settings)
      end
    end
  end
end
