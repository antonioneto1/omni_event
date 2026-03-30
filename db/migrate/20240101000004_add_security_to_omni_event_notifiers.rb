class AddSecurityToOmniEventNotifiers < ActiveRecord::Migration[6.1]
  def change
    add_column :omni_event_notifiers, :secret_key,          :string
    add_column :omni_event_notifiers, :timestamp_tolerance, :integer, default: 300, null: false

    add_index :omni_event_notifiers, :secret_key, unique: true, where: "secret_key IS NOT NULL"
  end
end
