# frozen_string_literal: true

# == Schema Information
#
# Table name: quantum_quarks
#
#  id           :string           not null, primary key
#  flavor       :string           not null, comment: "Quark flavor: up, down, charm, strange, top, bottom"
#  color_charge :string           not null, comment: "Color charge: red, green, blue"
#  mass         :float            comment: "Quark mass in MeV/c²"
#  proton_id    :string           comment: "Which proton contains this quark"
#  neutron_id   :string           comment: "Which neutron contains this quark"
#  confined     :boolean          default: true, comment: "Quarks are always confined in hadrons"
#  created_at   :datetime         not null, comment: "Classical time tracking"
#  updated_at   :datetime         not null, comment: "Classical time tracking"
#

# Quantum quarks confined in the SQLite hadron dimension 🔴🟢🔵
# The fundamental building blocks of protons and neutrons
class QuantumQuark < QuantumParticle
  FLAVORS = %w[up down charm strange top bottom].freeze
  COLOR_CHARGES = %w[red green blue].freeze

  validates :flavor, presence: true, inclusion: { in: FLAVORS }
  validates :color_charge, presence: true, inclusion: { in: COLOR_CHARGES }
  validates :mass, numericality: { greater_than: 0 }, allow_nil: true
  validate :must_be_confined_in_hadron

  scope :up_type, -> { where(flavor: %w[up charm top]) }
  scope :down_type, -> { where(flavor: %w[down strange bottom]) }
  scope :light_quarks, -> { where(flavor: %w[up down]) }
  scope :heavy_quarks, -> { where(flavor: %w[charm strange top bottom]) }
  scope :in_proton, -> { where.not(proton_id: nil) }
  scope :in_neutron, -> { where.not(neutron_id: nil) }

  # Quarks cannot exist alone in SQLite - they must be confined! 🔒
  def charge
    case flavor
    when "up", "charm", "top"
      +2.0/3.0  # Up-type quarks have +2/3 charge
    when "down", "strange", "bottom"
      -1.0/3.0  # Down-type quarks have -1/3 charge
    end
  end

  def antiparticle_flavor
    "anti_#{flavor}"
  end

  def color_neutral_with?(quark1, quark2)
    return false unless quark1.is_a?(QuantumQuark) && quark2.is_a?(QuantumQuark)
    colors = [ color_charge, quark1.color_charge, quark2.color_charge ].sort
    colors == %w[blue green red] # RGB = white (color neutral)
  end

  private

  def must_be_confined_in_hadron
    return if proton_id.present? || neutron_id.present?
    errors.add(:base, "Quarks must be confined in either a proton or neutron (color confinement)")
  end
end
