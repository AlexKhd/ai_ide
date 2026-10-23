class Vserver < ApplicationRecord
  has_many :deployments, dependent: :destroy

  after_update_commit :broadcast_card_update

  private

  def broadcast_card_update
    broadcast_replace_to(
      "vservers",
      target: ActionView::RecordIdentifier.dom_id(self, :card),
      partial: "vservers/vserver_card",
      locals: { vserver: self }
    )
  end
end
