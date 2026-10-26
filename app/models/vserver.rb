class Vserver < ApplicationRecord
  has_many :deployments, dependent: :destroy

  after_update_commit :broadcast_card_update

  validates :ssh_port,
          presence: true,
          numericality: {
            only_integer: true,
            greater_than_or_equal_to: 1,
            less_than_or_equal_to: 65_535
          }

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
