# frozen_string_literal: true

# == Schema Information
#
# Table name: quantum_photons
#
#  id          :string           not null, primary key
#  wavelength  :string           not null, comment: "Light wavelength in nanometers"
#  energy_level:float            comment: "Photon energy in electron volts"
#  polarized   :boolean          default: false, comment: "Is the photon polarized?"
#  source_star :string           comment: "Which star emitted this photon"
#  created_at  :datetime         not null, comment: "Classical time tracking"
#  updated_at  :datetime         not null, comment: "Classical time tracking"
#

# Quantum photons traveling through the SQLite dimension ✨
# These massless particles carry electromagnetic energy in discrete packets
class QuantumPhoton < QuantumParticle
  validates :wavelength, presence: true, numericality: { greater_than: 0 }
  validates :energy_level, numericality: { greater_than: 0 }, allow_nil: true
  validates :spin_state, inclusion: { in: %w[left_circular right_circular linear] }, allow_nil: true

  scope :visible_light, -> { where(wavelength: 380..700) }
  scope :polarized, -> { where(polarized: true) }
  scope :from_star, ->(star) { where(source_star: star) }

  # Photons always travel at the speed of light in SQLite vacuum! 🌟
  def speed_of_light
    299_792_458 # meters per second
  end

  def frequency
    return nil unless wavelength.present?
    speed_of_light / (wavelength.to_f * 1e-9) # Hz
  end
end