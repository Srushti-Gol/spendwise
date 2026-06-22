puts 'Seeding demo data...'

[AuditLog, Invoice, GoodsReceipt, PurchaseOrder, Requisition,
 ApprovalStep, ApprovalRule, User, Tenant].each(&:delete_all)

acme = Tenant.create!(name: 'Acme Corporation', subdomain: 'acme', plan: 'enterprise')

ActsAsTenant.with_tenant(acme) do
  admin    = User.create!(tenant: acme, name: 'Alice Admin',   email: 'admin@acme.com',    password: 'password123', role: 'admin',    department: 'IT')
  director = User.create!(tenant: acme, name: 'Dave Director', email: 'director@acme.com', password: 'password123', role: 'director', department: 'Finance')
  finance  = User.create!(tenant: acme, name: 'Faye Finance',  email: 'finance@acme.com',  password: 'password123', role: 'finance',  department: 'Finance')
  manager  = User.create!(tenant: acme, name: 'Mike Manager',  email: 'manager@acme.com',  password: 'password123', role: 'manager',  department: 'Engineering')
  staff    = User.create!(tenant: acme, name: 'Sam Staff',     email: 'staff@acme.com',    password: 'password123', role: 'staff',    department: 'Engineering')

  ApprovalRule.create!(tenant: acme, level: 1, approver_role: 'manager',  min_amount: 0,       max_amount: 10_000)
  ApprovalRule.create!(tenant: acme, level: 2, approver_role: 'finance',  min_amount: 10_001,  max_amount: 100_000)
  ApprovalRule.create!(tenant: acme, level: 3, approver_role: 'director', min_amount: 100_001)

  req1 = Requisition.create!(tenant: acme, requester: staff, title: 'MacBook Pro laptops for engineering', department: 'Engineering', total_amount: 7_500, status: 'pending', current_approver: manager, self_approval_blocked: true)
  req1.requisition_items.create!(description: 'MacBook Pro 14" M3', quantity: 3, unit_price: 2_500, total_price: 7_500)
  ApprovalStep.create!(tenant: acme, requisition: req1, approver: manager, level: 1, status: 'pending')

  req2 = Requisition.create!(tenant: acme, requester: staff, title: 'AWS cloud infrastructure expansion', department: 'Engineering', total_amount: 50_000, status: 'approved', self_approval_blocked: true)
  req2.requisition_items.create!(description: 'EC2 reserved instances - 1yr', quantity: 1, unit_price: 50_000, total_price: 50_000)
  ApprovalStep.create!(tenant: acme, requisition: req2, approver: manager, level: 1, status: 'approved', comment: 'Budget approved', decided_at: 2.days.ago)
  ApprovalStep.create!(tenant: acme, requisition: req2, approver: finance, level: 2, status: 'approved', comment: 'Finance signed off', decided_at: 1.day.ago)

  req3 = Requisition.create!(tenant: acme, requester: staff, title: 'Office furniture for new hires', department: 'HR', total_amount: 3_200, status: 'draft', self_approval_blocked: true)
  req3.requisition_items.create!(description: 'Standing desk ergonomic', quantity: 4, unit_price: 800, total_price: 3_200)

  req4 = Requisition.create!(tenant: acme, requester: staff, title: 'Figma annual licenses', department: 'Design', total_amount: 1_440, status: 'rejected', self_approval_blocked: true)
  req4.requisition_items.create!(description: 'Figma Professional seat', quantity: 12, unit_price: 120, total_price: 1_440)

  req5 = Requisition.create!(tenant: acme, requester: staff, title: 'Security audit tools subscription', department: 'Engineering', total_amount: 120_000, status: 'pending', current_approver: director, self_approval_blocked: true)
  req5.requisition_items.create!(description: 'Penetration testing platform annual', quantity: 1, unit_price: 120_000, total_price: 120_000)
  ApprovalStep.create!(tenant: acme, requisition: req5, approver: manager, level: 1, status: 'approved', decided_at: 1.day.ago)
  ApprovalStep.create!(tenant: acme, requisition: req5, approver: finance, level: 2, status: 'approved', decided_at: 12.hours.ago)
  ApprovalStep.create!(tenant: acme, requisition: req5, approver: director, level: 3, status: 'pending')

  po1 = PurchaseOrder.create!(tenant: acme, vendor: 'TechCorp Solutions', vendor_email: 'orders@techcorp.com', total_amount: 50_000, status: 'sent', created_by: manager, requisition: req2, price_tolerance: 0.05, quantity_tolerance: 0.02, expected_delivery_date: 7.days.from_now)
  po1.purchase_order_items.create!(description: 'EC2 Reserved Instances 1yr', quantity: 1, unit_price: 50_000, total_price: 50_000)

  po2 = PurchaseOrder.create!(tenant: acme, vendor: 'Apple Business', vendor_email: 'business@apple.com', total_amount: 7_500, status: 'received', created_by: manager, price_tolerance: 0.03, quantity_tolerance: 0.01)
  po_item = po2.purchase_order_items.create!(description: 'MacBook Pro 14" M3', quantity: 3, unit_price: 2_500, total_price: 7_500, received_quantity: 3)

  gr = GoodsReceipt.create!(tenant: acme, purchase_order: po2, received_by: staff, received_at: Date.today, notes: 'All units in excellent condition', delivery_reference: 'DHL-789456123')
  gr.goods_receipt_items.create!(purchase_order_item: po_item, quantity_received: 3, condition: 'good')

  inv1 = Invoice.create!(tenant: acme, vendor: 'TechCorp Solutions', invoice_number: 'TC-2024-001', total_amount: 51_500, currency: 'USD', invoice_date: Date.today, status: 'exception', created_by: finance, purchase_order: po1, price_match: false, quantity_match: true, vendor_match: true, price_variance: 0.03, quantity_variance: 0, match_result: { exceptions: ['Price variance 3.0% exceeds tolerance 2.0%'] }, processed_at: 1.hour.ago)
  inv2 = Invoice.create!(tenant: acme, vendor: 'Apple Business', invoice_number: 'AAPL-2024-55123', total_amount: 7_500, currency: 'USD', invoice_date: 3.days.ago, status: 'matched', created_by: finance, purchase_order: po2, price_match: true, quantity_match: true, vendor_match: true, price_variance: 0, quantity_variance: 0, match_result: { exceptions: [] }, processed_at: 2.days.ago)
  inv3 = Invoice.create!(tenant: acme, vendor: 'Office Depot', invoice_number: 'OD-78901', total_amount: 2_400, currency: 'USD', invoice_date: Date.today, status: 'pending', created_by: finance)

  AuditLog.create!(tenant: acme, user: staff,   action: 'create',  auditable_type: 'Requisition', auditable_id: req1.id, changes_data: { title: req1.title }, ip_address: '192.168.1.100')
  AuditLog.create!(tenant: acme, user: staff,   action: 'submit',  auditable_type: 'Requisition', auditable_id: req1.id, changes_data: { status: 'pending' }, ip_address: '192.168.1.100')
  AuditLog.create!(tenant: acme, user: manager, action: 'approve', auditable_type: 'Requisition', auditable_id: req2.id, changes_data: { comment: 'Budget approved' }, ip_address: '10.0.0.5')
  AuditLog.create!(tenant: acme, user: finance, action: 'approve', auditable_type: 'Requisition', auditable_id: req2.id, changes_data: { comment: 'Finance signed off' }, ip_address: '10.0.0.8')
  AuditLog.create!(tenant: acme, user: finance, action: 'create',  auditable_type: 'Invoice', auditable_id: inv1.id, changes_data: { vendor: inv1.vendor, amount: inv1.total_amount }, ip_address: '10.0.0.8')
  AuditLog.create!(tenant: acme, user: finance, action: 'create',  auditable_type: 'Invoice', auditable_id: inv2.id, changes_data: { vendor: inv2.vendor, amount: inv2.total_amount }, ip_address: '10.0.0.8')
end

puts "Done! Tenant: acme | Login: manager@acme.com / password123"
