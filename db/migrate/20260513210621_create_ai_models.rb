class CreateAiModels < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_models do |t|
      t.references :ai_connection,
                   null: false,
                   foreign_key: true
      t.string  :external_id, null: false
      t.string  :name, null: false
      t.string  :provider, null: false

      t.integer :context_length

      t.json    :input_modalities
      t.json    :output_modalities

      t.boolean :supports_tools, default: false
      t.boolean :supports_reasoning, default: false

      t.decimal :prompt_price, precision: 12, scale: 8
      t.decimal :completion_price, precision: 12, scale: 8

      t.json :architecture
      t.json :raw

      t.timestamps
    end

    add_index :ai_models, :provider
    add_index :ai_models, [:ai_connection_id, :external_id], unique: true
  end
end
