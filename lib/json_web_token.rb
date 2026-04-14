module JsonWebToken
  SECRET_KEY = ENV.fetch('JWT_SECRET', 'spendwise_dev_secret_change_in_production')
  ALGORITHM = 'HS256'
  EXPIRY = 7.days

  def self.encode(payload)
    payload[:exp] ||= EXPIRY.from_now.to_i
    JWT.encode(payload, SECRET_KEY, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: ALGORITHM)
    HashWithIndifferentAccess.new(decoded.first)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
