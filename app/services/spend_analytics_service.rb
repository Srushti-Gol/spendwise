class SpendAnalyticsService
  def initialize(tenant, options = {})
    @tenant = tenant
    @from = options[:from] || 12.months.ago
    @to   = options[:to] || Time.current
  end

  def monthly_spend
    Invoice.where(tenant: @tenant)
           .where(invoice_date: @from..@to)
           .where(status: %w[matched approved paid])
           .group("DATE_TRUNC('month', invoice_date)")
           .order("DATE_TRUNC('month', invoice_date)")
           .sum(:total_amount)
           .map { |month, total| { month: month.strftime("%Y-%m"), total: total.to_f } }
  end

  def top_vendors(limit: 10)
    Invoice.where(tenant: @tenant)
           .where(invoice_date: @from..@to)
           .where(status: %w[matched approved paid])
           .group(:vendor)
           .order("sum_total_amount DESC")
           .limit(limit)
           .sum(:total_amount)
           .map { |vendor, total| { vendor: vendor, total: total.to_f } }
  end

  def exception_rate
    total = Invoice.where(tenant: @tenant).where(invoice_date: @from..@to).count
    exceptions = Invoice.where(tenant: @tenant)
                        .where(invoice_date: @from..@to)
                        .where(status: "exception").count
    return 0 if total.zero?
    (exceptions.to_f / total * 100).round(2)
  end

  def department_spend
    Requisition.where(tenant: @tenant)
               .where(status: "ordered")
               .where(created_at: @from..@to)
               .group(:department)
               .sum(:total_amount)
               .map { |dept, total| { department: dept, total: total.to_f } }
               .sort_by { |d| -d[:total] }
  end
end
