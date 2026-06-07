class RequisitionSerializer < ActiveModel::Serializer
  attributes :id, :title, :department, :status, :total_amount, :currency,
             :self_approval_blocked, :created_at, :updated_at

  belongs_to :requester, serializer: UserSerializer
  belongs_to :current_approver, serializer: UserSerializer
  has_many :requisition_items
  has_many :approval_steps
end
