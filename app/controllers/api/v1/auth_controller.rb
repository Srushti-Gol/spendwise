module Api
  module V1
    class AuthController < ActionController::API
      def register
        tenant = Tenant.find_or_create_by!(subdomain: params[:subdomain] || 'default') do |t|
          t.name = params[:company_name] || 'My Company'
        end

        user = User.new(user_params.merge(tenant: tenant))
        if user.save
          render json: { token: generate_token(user), user: user_payload(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: params[:email])
        if user&.authenticate(params[:password])
          render json: { token: generate_token(user), user: user_payload(user) }
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      def me
        token = request.headers['Authorization']&.split(' ')&.last
        payload = JWT.decode(token, jwt_secret, true, algorithm: 'HS256').first
        user = User.find(payload['user_id'])
        render json: user_payload(user)
      rescue JWT::DecodeError
        render json: { error: 'Invalid token' }, status: :unauthorized
      end

      private

      def user_params
        params.permit(:name, :email, :password, :role, :department)
      end

      def generate_token(user)
        payload = { user_id: user.id, tenant_id: user.tenant_id, exp: 7.days.from_now.to_i }
        JWT.encode(payload, jwt_secret, 'HS256')
      end

      def jwt_secret
        ENV.fetch('JWT_SECRET', 'fallback_secret_change_in_production')
      end

      def user_payload(user)
        { id: user.id, name: user.name, email: user.email, role: user.role,
          department: user.department, tenant_id: user.tenant_id }
      end
    end
  end
end
