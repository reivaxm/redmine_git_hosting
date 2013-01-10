# encoding: utf-8
require 'redmine'
require_dependency 'project'
require_dependency 'principal'
require_dependency 'user'

require_dependency File.join(File.dirname(__FILE__), 'app', 'models', 'git_repository_extra')
require_dependency File.join(File.dirname(__FILE__), 'app', 'models', 'git_cia_notification')

Redmine::Plugin.register :redmine_git_hosting do
  name 'Redmine Git Hosting Plugin'
  author 'Eric Bishop, Pedro Algarvio, Christian Käser, Zsolt Parragi, Yunsang Choi, Joshua Hogendorn, Jan Schulz-Hofen, John Kubiatowicz, Xavier MORTELETTE and others'
  description 'Enables Redmine / ChiliProject to control hosting of git repositories'
  version '0.4.6'
  url 'https://github.com/reivaxm/redmine_git_hosting'

  settings :default => {
    'httpServer' => 'localhost',
    'httpServerSubdir' => '',
    'gitServer' => 'localhost',
    'gitUser' => 'gitolite',
    'gitRepositoryBasePath' => 'repositories/',
    'gitRedmineSubdir' => '',
    'gitRepositoryHierarchy' => 'true',
    'gitRecycleBasePath' => 'recycle_bin/',
    'gitRecycleExpireTime' => '24.0',
    'gitLockWaitTime' => '10',
    'gitoliteIdentityFile' => Rails.root.to_s + '/.ssh/gitolite_admin_id_rsa',
    'gitoliteIdentityPublicKeyFile' => Rails.root.to_s + '/.ssh/gitolite_admin_id_rsa.pub',
    'allProjectsUseGit' => 'false',
    'gitDaemonDefault' => '1',    # Default is Daemon enabled
    'gitHttpDefault' => '1',      # Default is HTTP_ONLY
    'gitNotifyCIADefault' => '0', # Default is CIA Notification disabled
    'deleteGitRepositories' => 'false',
    'gitRepositoriesShowUrl' => 'true',
    'gitCacheMaxTime' => '-1',
    'gitCacheMaxElements' => '100',
    'gitCacheMaxSize' => '16',
    'gitHooksDebug' => 'false',
    'gitHooksAreAsynchronous' => 'true',
    'gitTempDataDir' => '/tmp/redmine_git_hosting/',
    'gitScriptDir' => ''
  },
    :partial => 'redmine_git_hosting'
  project_module :repository do
    permission :create_repository_mirrors, :repository_mirrors => :create
    permission :view_repository_mirrors, :repository_mirrors => :index
    permission :edit_repository_mirrors, :repository_mirrors => :edit
  end
end

#Rails.configuration.to_prepare do
RedmineApp::Application.config.to_prepare do

  require_dependency 'git_hosting'

  # initialize association from project -> repository mirrors
  Project.send(:has_many, :repository_mirrors, :dependent => :destroy)

  require_dependency 'projects_controller'
  require_dependency 'git_hosting/patches/projects_controller_patch'
  ProjectsController.send(:include, GitHosting::Patches::ProjectsControllerPatch)

  require_dependency 'repositories_controller'
  require_dependency 'git_hosting/patches/repositories_controller_patch'
  RepositoriesController.send(:include, GitHosting::Patches::RepositoriesControllerPatch)

  require_dependency 'repository'
  require_dependency 'git_hosting/patches/repository_patch'
  Repository.send(:include, GitHosting::Patches::RepositoryPatch)

  require_dependency 'stringio'
  require_dependency 'redmine/scm/adapters/git_adapter'
  require_dependency 'git_hosting/patches/git_adapter_patch'
  Redmine::Scm::Adapters::GitAdapter.send(:include, GitHosting::Patches::GitAdapterPatch)

  require_dependency 'groups_controller'
  require_dependency 'git_hosting/patches/groups_controller_patch'
  GroupsController.send(:include, GitHosting::Patches::GroupsControllerPatch)

  require_dependency 'repository'
  require_dependency 'repository/git'
  require_dependency 'git_hosting/patches/git_repository_patch'
  Repository::Git.send(:include, GitHosting::Patches::GitRepositoryPatch)

  require_dependency 'sys_controller'
  require_dependency 'git_hosting/patches/sys_controller_patch'
  SysController.send(:include, GitHosting::Patches::SysControllerPatch)

  require_dependency 'members_controller'
  require_dependency 'git_hosting/patches/members_controller_patch'
  MembersController.send(:include, GitHosting::Patches::MembersControllerPatch)

  # initialize association from user -> public keys
  User.send(:has_many, :gitolite_public_keys, :dependent => :destroy)

  require_dependency 'users_controller'
  require_dependency 'git_hosting/patches/users_controller_patch'
  UsersController.send(:include, GitHosting::Patches::UsersControllerPatch)

  require_dependency 'users_helper'
  require_dependency 'git_hosting/patches/users_helper_patch'
  UsersHelper.send(:include, GitHosting::Patches::UsersHelperPatch)

  require_dependency 'roles_controller'
  require_dependency 'git_hosting/patches/roles_controller_patch'
  RolesController.send(:include, GitHosting::Patches::RolesControllerPatch)

  require_dependency 'my_controller'
  require_dependency 'git_hosting/patches/my_controller_patch'
  MyController.send(:include, GitHosting::Patches::MyControllerPatch)

  require_dependency 'git_hosting/patches/repository_cia_filters'

end

# initialize hooks
class GitProjectShowHook < Redmine::Hook::ViewListener
  render_on :view_projects_show_left, :partial => 'git_urls'
end

class GitRepoUrlHook < Redmine::Hook::ViewListener
  render_on :view_repositories_show_contextual, :partial => 'git_urls'
end


# initialize observer
RedmineApp::Application.configure do
  config.after_initialize do
    if config.action_controller.perform_caching
      ActiveRecord::Base.observers = ActiveRecord::Base.observers << GitHostingObserver
      ActiveRecord::Base.observers = ActiveRecord::Base.observers << GitHostingSettingsObserver

      config.to_prepare do
        GitHostingObserver.instance.reload_this_observer
      end
      config.to_prepare do
        GitHostingSettingsObserver.instance.reload_this_observer
      end
    end
  end
end

