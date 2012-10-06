class CreateGitCaches < ActiveRecord::Migration
	def self.up
		create_table :git_caches do |t|
			t.column :command, :text
			t.column :command_output, :binary
			t.column :proj_identifier, :string
			t.timestamps
		end
		add_index :git_caches, :command, :length =>32
	end

	def self.down
		drop_table :git_caches
	end
end
