class ExtendChangesetsNotifiedCia < ActiveRecord::Migration
	def self.up
        Changeset.reset_column_information
		add_column(:changesets, :notified_cia, :integer, :default=>0) unless Changeset.column_names.include?('notified_cia')
	end

	def self.down
        Changeset.reset_column_information
		remove_column(:changesets, :notified_cia) if Changeset.column_names.include?('notified_cia')
	end
end
