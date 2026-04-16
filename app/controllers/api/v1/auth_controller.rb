module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_user!, only: [:register, :login]
      skip_before_action :set_tenant, only: [:register, :login]

      def register
        tenant = Tenant.find_or_create_by!(subdomain: register_params[:subdomain] || 'default') do |t|
          t.name = register_params[:company_name] || 'My Company'
        end

        user = User.new(register_params.except(:subdomain, :company_name).merge(tenant: tenant))
        if user.save
          token = JsonWebToken.encode(user_id: user.id, jti: user.jti)
          render json: { token: token, user: user_json(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: login_params[:email])
        if user&.authenticate(login_params[:password])
          token = JsonWebToken.encode(user_id: user.id, jti: user.jti)
          render json: { token: token, user: user_json(user) }
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      def me
        render json: user_json(current_user)
      end

      private

      def register_params
        params.permit(:name, :email, :password, :role, :department, :subdomain, :company_name)
      end

      def login_params
        params.permit(:email, :password)
      end

      def user_json(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          department: user.department,
          tenant_id: user.tenant_id
        }
      end
    end
  end
end
