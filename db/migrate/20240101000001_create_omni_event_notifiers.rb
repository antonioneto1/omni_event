class CreateOmniEventNotifiers < ActiveRecord::Migration[6.1]
  def change
    create_table :omni_event_notifiers do |t|
      t.string  :name,       null: false
      t.string  :token,      null: false
      t.boolean :check_ip,   null: false, default: false
      t.jsonb   :allowed_ips, null: false, default: []
      t.timestamps
    end

    add_index :omni_event_notifiers, :token, unique: true
  end
end
