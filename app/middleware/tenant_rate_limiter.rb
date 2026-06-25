class TenantRateLimiter
  LIMIT  = 500
  WINDOW = 60

  def initialize(app)
    @app   = app
    @redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379"))
  end

  def call(env)
    request = Rack::Request.new(env)
    key     = rate_limit_key(request)
    count   = @redis.incr(key)
    @redis.expire(key, WINDOW) if count == 1

    if count > LIMIT
      return [ 429, { "Content-Type" => "application/json" },
              [ { error: "Rate limit exceeded", retry_after: WINDOW }.to_json ] ]
    end

    @app.call(env)
  end

  private

  def rate_limit_key(request)
    tenant_id = request.env["HTTP_X_TENANT_ID"] || request.ip
    "rl:#{tenant_id}:#{Time.now.to_i / WINDOW}"
  end
end
