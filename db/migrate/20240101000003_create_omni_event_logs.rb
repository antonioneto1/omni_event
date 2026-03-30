class CreateOmniEventLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :omni_event_logs do |t|
      t.references :loggable, polymorphic: true, null: true
      t.string :action_type, null: false, default: 'system_info'
      t.text   :content
      t.jsonb  :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :omni_event_logs, :action_type
    add_index :omni_event_logs, :created_at
  end
end
