# Seeds create a demo tenant, users across all roles, and sample data

puts "Seeding demo data..."

tenant = Tenant.find_or_create_by!(name: 'AcmeCorp', subdomain: 'acme') do |t|
  t.settings = { currency: 'USD', approval_threshold: 5000 }
end

users = {
  admin:    User.find_or_create_by!(email: 'admin@acme.com')    { |u| u.assign_attributes(name: 'Alice Admin',    role: 'admin',    tenant: tenant, password: 'password123') },
  director: User.find_or_create_by!(email: 'director@acme.com') { |u| u.assign_attributes(name: 'Dave Director',  role: 'director', tenant: tenant, password: 'password123') },
  finance:  User.find_or_create_by!(email: 'finance@acme.com')  { |u| u.assign_attributes(name: 'Faye Finance',   role: 'finance',  tenant: tenant, password: 'password123') },
  manager:  User.find_or_create_by!(email: 'manager@acme.com')  { |u| u.assign_attributes(name: 'Mike Manager',   role: 'manager',  tenant: tenant, password: 'password123') },
  staff:    User.find_or_create_by!(email: 'staff@acme.com')    { |u| u.assign_attributes(name: 'Sam Staff',      role: 'staff',    tenant: tenant, password: 'password123') },
}

ActsAsTenant.with_tenant(tenant) do
  # Approval rules
  ApprovalRule.find_or_create_by!(department: 'ALL', step_order: 1, tenant: tenant) do |r|
    r.approver = users[:manager]
    r.min_amount = 0
  end
  ApprovalRule.find_or_create_by!(department: 'ALL', step_order: 2, tenant: tenant) do |r|
    r.approver = users[:director]
    r.min_amount = 10_000
  end

  # Sample requisitions
  5.times do |i|
    req = Requisition.find_or_create_by!(title: "Office Supplies Q#{i + 1}", tenant: tenant) do |r|
      r.department    = 'Operations'
      r.requester     = users[:staff]
      r.total_amount  = (500 + i * 300).to_f
      r.currency      = 'USD'
      r.status        = 'draft'
    end
    req.requisition_items.find_or_create_by!(description: "Item #{i + 1}") do |item|
      item.quantity   = 10
      item.unit_price = req.total_amount / 10
    end
  end

  # Sample invoices
  3.times do |i|
    Invoice.find_or_create_by!(invoice_number: "INV-2024-#{1000 + i}", tenant: tenant) do |inv|
      inv.vendor       = "Vendor #{('A'.ord + i).chr}"
      inv.total_amount = (1200 + i * 500).to_f
      inv.currency     = 'USD'
      inv.invoice_date = i.months.ago
      inv.created_by   = users[:finance]
    end
  end
end

puts "Done! Login with admin@acme.com / password123"
