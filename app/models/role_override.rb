#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class RoleOverride < ActiveRecord::Base
  belongs_to :context, :polymorphic => true
  has_many :children, :class_name => "Role", :foreign_key => "parent_id"
  belongs_to :parent, :class_name => "Role"
  before_save :default_values

  attr_accessible :context, :permission, :enrollment_type, :enabled
  
  def default_values
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end
  
  def self.account_membership_types(account)
    res = [{:name => "AccountAdmin", :label => t('roles.account_admin', "Account Admin")}]
    (account.account_membership_types - ['AccountAdmin']).each do |t| 
      res << {:name => t, :label => t}
    end
    res
  end

  ENROLLMENT_TYPES =
    [
      {:name => 'StudentEnrollment', :label => lambda { t('roles.student', 'Student') } },
      {:name => 'TaEnrollment', :label => lambda { t('roles.ta', 'TA') } },
      {:name => 'TeacherEnrollment', :label => lambda { t('roles.teacher', 'Teacher') } },
      {:name => 'DesignerEnrollment', :label => lambda { t('roles.designer', 'Course Designer') } },
      {:name => 'ObserverEnrollment', :label => lambda { t('roles.observer', 'Observer') } }
    ].freeze
  def self.enrollment_types
    ENROLLMENT_TYPES
  end

  KNOWN_ROLE_TYPES =
    [
      'TeacherEnrollment',
      'TaEnrollment',
      'DesignerEnrollment',
      'StudentEnrollment',
      'ObserverEnrollment',
      'TeacherlessStudentEnrollment',
      'AccountAdmin'
    ].freeze
  def self.known_role_types
    KNOWN_ROLE_TYPES
  end

  PERMISSIONS =
    {
      :manage_wiki => {
        :label => lambda { t('permissions.manage_wiki', "Manage Wiki (add / edit / delete pages)") },
        :available_to => [
          'TaEnrollment',
          'TeacherEnrollment',
          'DesignerEnrollment',
          'TeacherlessStudentEnrollment',
          'ObserverEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'TaEnrollment',
          'TeacherEnrollment',
          'DesignerEnrollment',
          'AccountAdmin'
        ]
      },
      :post_to_forum => {
        :label => lambda { t('permissions.post_to_forum', "Post to discussions") },
        :available_to => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherlessStudentEnrollment',
          'ObserverEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :moderate_forum => {
        :label => lambda { t('permissions.moderate_form', "Moderate discussions ( delete / edit other's posts, lock topics)") },
        :available_to => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'TeacherlessStudentEnrollment',
          'ObserverEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :send_messages => {
        :label => lambda { t('permissions.send_messages', "Send messages to course members") },
        :available_to => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'TeacherlessStudentEnrollment',
          'ObserverEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :manage_outcomes => {
        :label => lambda { t('permissions.manage_outcomes', "Manage Learning Outcomes") },
        :available_to => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'TeacherlessStudentEnrollment',
          'ObserverEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'DesignerEnrollment',
          'TeacherEnrollment',
          'TeacherlessStudentEnrollment',
          'AccountAdmin'
        ]
      },
      :create_conferences => {
        :label => lambda { t('permissions.create_conferences', "Create web conferences") },
        :available_to => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'TeacherlessStudentEnrollment',
          'ObserverEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :create_collaborations => {
        :label => lambda { t('permissions.create_collaborations', "Create student collaborations") },
        :available_to => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'TeacherlessStudentEnrollment',
          'ObserverEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :read_roster => {
        :label => lambda { t('permissions.read_roster', "See the list of users") },
        :available_to => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'TeacherlessStudentEnrollment',
          'ObserverEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :view_all_grades => {
        :label => lambda { t('permissions.view_all_grades', "View all grades") },
        :available_to => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :manage_grades => {
        :label => lambda { t('permissions.manage_grades', "Edit grades (includes assessing rubrics)") },
        :available_to => [
          'TaEnrollment',
          'TeacherEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'TaEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :comment_on_others_submissions => {
        :label => lambda { t('permissions.comment_on_others_submissions', "View all students' submissions and make comments on them") },
        :available_to => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'TeacherlessStudentEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :manage_students => {
        :label => lambda { t('permissions.manage_students', "Add/Remove students for the course") },
        :available_to => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'TeacherlessStudentEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :manage_admin_users => {
        :label => lambda { t('permissions.manage_admin_users', "Add/Remove other teachers, Course Designers or TAs to the course") },
        :available_to => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :manage_role_overrides => {
        :label => lambda { t('permissions.manage_role_overrides', "Manage default role permissions (define these permissions for course role types)") },
        :available_to => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :manage_account_memberships => {
        :label => lambda { t('permissions.manage_account_memberships', "Add/Remove other admins for the account") },
        :available_to => [
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'AccountAdmin'
        ],
        :account_only => true
      },
      :manage_account_settings => {
        :label => lambda { t('permissions.manage_account_settings', "Manage account-level settings") },
        :available_to => [
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'AccountAdmin'
        ],
        :account_only => true
      },
      :manage_groups => {
        :label => lambda { t('permissions.manage_groups', "Manage (create / edit / delete) groups") },
        :available_to => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :view_group_pages => {
        :label => lambda { t('permissions.view_group_pages', "View the group pages of all student groups") },
        :available_to => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'ObserverEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :manage_files => {
        :label => lambda { t('permissions.manage_files', "Manage (add / edit / delete) course files") },
        :available_to => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'TeacherlessStudentEnrollment',
          'ObserverEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :manage_assignments => {
        :label => lambda { t('permissions.manage_assignments', "Manage (add / edit / delete) assignments and quizzes") },
        :available_to => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'TeacherlessStudentEnrollment',
          'ObserverEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :manage_calendar => {
        :label => lambda { t('permissions.manage_calendar', "Add, edit and delete events on the course calendar") },
        :available_to => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'TeacherlessStudentEnrollment',
          'ObserverEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :read_reports => {
        :label => lambda { t('permissions.read_reports', "View usage reports for the course") },
        :available_to => [
          'StudentEnrollment',
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin',
          'AccountMembership'
        ],
        :true_for => [
          'TaEnrollment',
          'DesignerEnrollment',
          'TeacherEnrollment',
          'AccountAdmin'
        ]
      },
      :manage_courses => {
        :label => lambda { t('permissions.manage_courses', "Add/Remove Courses for the account") },
        :available_to => [
          'AccountAdmin',
          'AccountMembership'
        ],
        :account_only => true,
        :true_for => [
          'AccountAdmin'
        ]
      },
      :manage_user_logins => {
        :label => lambda { t('permissions.manage_user_logins', "Modify Login details for users") },
        :available_to => [
          'AccountAdmin',
          'AccountMembership'
        ],
        :account_only => true,
        :true_for => [
          'AccountAdmin'
        ]
      },
      :manage_alerts => {
        :label => lambda { t('permissions.manage_alerts', "Manage account user alerts") },
        :account_only => true,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership),
      },

      :site_admin => {
        :label => lambda { t('permissions.site_admin', "Use the Site Admin section and admin all other accounts") },
        :account_only => :site_admin,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership),
      },
      :become_user => {
        :label => lambda { t('permissions.become_user', "Become other users") },
        :account_only => :root,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership),
      },
      :manage_site_settings => {
        :label => lambda { t('permissions.manage_site_settings', "Manage site-wide and plugin settings") },
        :account_only => :site_admin,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership),
      },
      :manage_sis => {
        :label => lambda { t('permissions.manage_sis', "Import and manage SIS data") },
        :account_only => true,
        :true_for => %w(AccountAdmin),
        :available_to => %w(AccountAdmin AccountMembership),
      },
    }.freeze
  def self.permissions
    PERMISSIONS
  end

  def self.css_class_for(context, permission, enrollment_type)
    generated_permission = self.permission_for(context, permission, enrollment_type)
    
    css = []
    if generated_permission[:readonly]
      css << "six-checkbox-disabled-#{generated_permission[:enabled] ? 'checked' : 'unchecked' }"
    else
      if generated_permission[:explicit]
        css << "six-checkbox-default-#{generated_permission[:prior_default] ? 'checked' : 'unchecked'}"
      end
      css << "six-checkbox#{generated_permission[:explicit] ? '' : '-default' }-#{generated_permission[:enabled] ? 'checked' : 'unchecked' }"
    end
    css.join(' ')
  end
  
  def self.readonly_for(context, permission, enrollment_type)
    self.permission_for(context, permission, enrollment_type)[:readonly]
  end
  
  def self.title_for(context, permission, enrollment_type)
    generated_permission = self.permission_for(context, permission, enrollment_type)
    if generated_permission[:readonly]
      t 'tooltips.readonly', "you do not have permission to change this."
    else
      t 'tooltips.toogle', "Click to toggle this permission ON or OFF"
    end
  end
  
  def self.locked_for(context, permission, enrollment_type=nil)
    self.permission_for(context, permission, enrollment_type)[:locked]
  end
  
  def self.hidden_value_for(context, permission, enrollment_type=nil)
    generated_permission = self.permission_for(context, permission, enrollment_type)
    if !generated_permission[:readonly] && generated_permission[:explicit]
      generated_permission[:enabled] ? 'checked' : 'unchecked'
    else
      ''
    end
  end
  
  def self.teacherless_permissions
    @teacherless_permissions ||= permissions.select{|p, data| data[:available_to].include?('TeacherlessStudentEnrollment') }.map{|p, data| p }
  end
  
  def self.clear_cached_contexts
    @@role_override_chain = {}
    @cached_permissions = {}
  end
  
  def self.permission_for(context, permission, enrollment_type=nil)
    @cached_permissions ||= {}
    key = [context.cache_key, permission.to_s, enrollment_type.to_s].join
    permissionless_key = [context.cache_key, enrollment_type.to_s].join
    return @cached_permissions[key] if @cached_permissions[key]
    
    fallback_enrollment_type = enrollment_type
    fallback_enrollment_type = 'AccountMembership' if !self.known_role_types.include?(enrollment_type)
    generated_permission = {
      :permission =>  self.permissions[permission],
      :enabled    =>  self.permissions[permission][:true_for].include?(fallback_enrollment_type),
      :locked     => !self.permissions[permission][:available_to].include?(fallback_enrollment_type),
      :readonly   => !self.permissions[permission][:available_to].include?(fallback_enrollment_type),
      :explicit   => false,
      :enrollment_type => enrollment_type
    }
    if context.is_a?(Enrollment)
      generated_permission.merge!({
        :enabled         =>  self.permissions[permission][:true_for].include?(context.class.to_s),
        :enrollment_type => context.class.to_s
      })
    end
    
    @@role_override_chain ||= {}
    overrides = @@role_override_chain[permissionless_key]
    unless overrides
      contexts = []
      context_walk = context
      while context_walk
        contexts << context_walk
        if context_walk.respond_to?(:course)
          context_walk = context_walk.course
        elsif context_walk.respond_to?(:account)
          context_walk = context_walk.account
        elsif context_walk.respond_to?(:parent_account)
          context_walk = context_walk.parent_account
        else
          context_walk = nil
        end
      end
      context_codes = contexts.reverse.map(&:asset_string)
      case_string = ""
      context_codes.each_with_index{|code, idx| case_string += " WHEN context_code='#{code}' THEN #{idx} " }
      overrides = RoleOverride.find(:all, :conditions => {:context_code => context_codes, :enrollment_type => generated_permission[:enrollment_type].to_s}, :order => "CASE #{case_string} ELSE 9999 END")
    end
    
    @@role_override_chain[permissionless_key] = overrides
    overrides.select{|o| o.permission == permission.to_s}.each do |override|
      if override
        generated_permission[:readonly] = true if override.locked && (override.context_id != context.id || override.context_type != context.class.to_s)
        generated_permission.merge!({ 
          :readonly => generated_permission[:readonly] || generated_permission[:locked],
          :explicit => false
        })
      
        if !generated_permission[:locked] && context_override = override
          unless context_override.enabled.nil?
            if context_override.context == context
              # if the explicit override is for the target context, the prior default
              # is the parent context's value
              generated_permission[:prior_default] = generated_permission[:enabled]
            else
              # otherwise, the prior default is the same as the new override,
              # since changing it in the target context will create a new
              # override
              generated_permission[:prior_default] = context_override.enabled?
            end
            generated_permission.merge!({
              :enabled => context_override.enabled?,
              :explicit => !context_override.enabled.nil?
            })
          end
          generated_permission[:locked] = context_override.locked?
        end
      end
    end
    @cached_permissions[key] = generated_permission
  end
  
end
