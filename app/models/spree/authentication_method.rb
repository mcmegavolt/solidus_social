# frozen_string_literal: true

class Spree::AuthenticationMethod < ApplicationRecord
  class << self
    def environment_credentials_for(provider)
      return {} unless provider.present?

      providers = ::Spree::SocialConfig.providers || {}
      creds = providers[provider.to_sym] || providers[provider.to_s]
      creds.respond_to?(:symbolize_keys) ? creds.symbolize_keys : (creds || {})
    rescue NoMethodError
      {}
    end
  end

  def self.provider_options
    SolidusSocial.configured_providers.map { |provider_name| [provider_name.split('_').first.camelize, provider_name] }
  end

  validates :provider, presence: true

  def self.active_authentication_methods?
    where(environment: ::Rails.env, active: true).exists?
  end

  scope :available_for, lambda { |user|
    sc = where(environment: ::Rails.env)
    sc = sc.where(['provider NOT IN (?)', user.user_authentications.map(&:provider)]) if user && !user.user_authentications.empty?
    sc
  }

  def environment_credentials
    self.class.environment_credentials_for(provider)
  end

  def managed_via_environment?
    creds = environment_credentials
    creds[:api_key].present? || creds[:api_secret].present?
  end
end
