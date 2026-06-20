class VendorMatchService
  SIMILARITY_THRESHOLD = 0.75

  def initialize(invoice_vendor, po_vendor)
    @invoice_vendor = invoice_vendor.to_s.downcase.strip
    @po_vendor      = po_vendor.to_s.downcase.strip
  end

  def match?
    return true if exact_match?
    return true if acronym_match?
    trigram_similarity >= SIMILARITY_THRESHOLD
  end

  def similarity_score
    trigram_similarity
  end

  private

  def exact_match?
    @invoice_vendor == @po_vendor
  end

  def acronym_match?
    words = @po_vendor.split
    return false if words.length < 2
    acronym = words.map { |w| w[0] }.join
    @invoice_vendor == acronym
  end

  def trigram_similarity
    return 0.0 if @invoice_vendor.empty? || @po_vendor.empty?
    inv_trigrams = trigrams(@invoice_vendor)
    po_trigrams  = trigrams(@po_vendor)
    intersection = (inv_trigrams & po_trigrams).length
    union        = (inv_trigrams | po_trigrams).length
    return 0.0 if union.zero?
    intersection.to_f / union
  end

  def trigrams(str)
    padded = "  #{str}  "
    padded.chars.each_cons(3).map(&:join)
  end
end
