puts 'Seeding database...'

# Tenants
acme = Tenant.find_or_create_by!(subdomain: 'acme') { |t| t.name = 'Acme Corp'; t.plan = 'enterprise' }
globex = Tenant.find_or_create_by!(subdomain: 'globex') { |t| t.name = 'Globex Inc'; t.plan = 'starter' }

ActsAsTenant.with_tenant(acme) do
  # Users
  admin = User.find_or_create_by!(email: 'admin@acme.com') do |u|
    u.name = 'Sarah Admin'; u.role = 'admin'; u.department = 'IT'
    u.password = 'password123'; u.tenant = acme
  end
  director = User.find_or_create_by!(email: 'director@acme.com') do |u|
    u.name = 'James Director'; u.role = 'director'; u.department = 'Finance'
    u.password = 'password123'; u.tenant = acme
  end
  finance = User.find_or_create_by!(email: 'finance@acme.com') do |u|
    u.name = 'Priya Finance'; u.role = 'finance'; u.department = 'Finance'
    u.password = 'password123'; u.tenant = acme
  end
  manager = User.find_or_create_by!(email: 'manager@acme.com') do |u|
    u.name = 'Tom Manager'; u.role = 'manager'; u.department = 'Engineering'
    u.password = 'password123'; u.tenant = acme
  end
  staff = User.find_or_create_by!(email: 'staff@acme.com') do |u|
    u.name = 'Alice Staff'; u.role = 'staff'; u.department = 'Engineering'
    u.password = 'password123'; u.tenant = acme
  end

  # Approval rules
  ApprovalRule.find_or_create_by!(tenant: acme, level: 1) do |r|
    r.approver_role = 'manager'; r.min_amount = 0; r.max_amount = 10_000
  end
  ApprovalRule.find_or_create_by!(tenant: acme, level: 2) do |r|
    r.approver_role = 'finance'; r.min_amount = 10_000; r.max_amount = 100_000
  end
  ApprovalRule.find_or_create_by!(tenant: acme, level: 3) do |r|
    r.approver_role = 'director'; r.min_amount = 100_000
  end

  # Sample requisitions
  req1 = Requisition.create!(
    tenant: acme, requester: staff, title: 'MacBook Pro laptops for engineering team',
    department: 'Engineering', total_amount: 7_500, status: 'pending',
    current_approver: manager
  )
  req1.requisition_items.create!(description: 'MacBook Pro 14"', quantity: 3, unit_price: 2_500, total_price: 7_500)
  ApprovalStep.create!(tenant: acme, requisition: req1, approver: manager, level: 1, status: 'pending')

  req2 = Requisition.create!(
    tenant: acme, requester: staff, title: 'AWS cloud infrastructure expansion',
    department: 'Engineering', total_amount: 50_000, status: 'approved'
  )
  req2.requisition_items.create!(description: 'EC2 reserved instances - 1 year', quantity: 1, unit_price: 50_000, total_price: 50_000)

  # Sample PO
  po = PurchaseOrder.create!(
    tenant: acme, vendor: 'TechCorp Solutions', vendor_email: 'orders@techcorp.com',
    total_amount: 50_000, status: 'sent', created_by: manager,
    requisition: req2, price_tolerance: 0.05, quantity_tolerance: 0.02
  )
  po.purchase_order_items.create!(description: 'EC2 Reserved Instances', quantity: 1, unit_price: 50_000, total_price: 50_000)

  # Sample invoice
  Invoice.create!(
    tenant: acme, vendor: 'TechCorp Solutions', invoice_number: 'TC-2024-001',
    total_amount: 51_500, currency: 'USD', invoice_date: Date.today,
    status: 'exception', created_by: finance, purchase_order: po,
    price_match: false, quantity_match: true, vendor_match: true,
    price_variance: 0.03,
    match_result: { exceptions: ['Price variance 3.0% exceeds tolerance 2.0%'] }
  )

  puts "Seeded Acme Corp: #{User.count} users, #{Requisition.count} requisitions, #{PurchaseOrder.count} POs, #{Invoice.count} invoices"
end

puts 'Done!'
