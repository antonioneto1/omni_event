class CreateOmniEventWebhookEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :omni_event_webhook_events do |t|
      t.references :webhook_notifier, null: false,
                   foreign_key: { to_table: :omni_event_notifiers }
      t.jsonb   :headers, null: false, default: {}
      t.jsonb   :payload, null: false, default: {}
      t.string  :status,  null: false, default: 'pending'
      t.timestamps
    end

    add_index :omni_event_webhook_events, :status
  end
end
